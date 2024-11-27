#!/bin/bash

# Prompt for AWS credentials
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo "*****************"
read -p "Enter your AWS Region (e.g., us-east-1): " AWS_REGION
read -p "Enter your ECR repository name: " ECR_REPO_NAME

# Configure AWS CLI with the provided credentials
echo "Configuring AWS CLI..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# Create ECR repository and fetch the repository URI
echo "Creating ECR repository..."
ECR_OUTPUT=$(aws ecr create-repository --repository-name "$ECR_REPO_NAME" 2>&1)
if echo "$ECR_OUTPUT" | grep -q 'already exists'; then
    echo "The ECR repository '$ECR_REPO_NAME' already exists."
else
    echo "ECR repository created: $ECR_REPO_NAME"
fi

# Get the ECR repository URI
REPOSITORY_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --query "repositories[0].repositoryUri" --output text)
echo "ECR Repository URI: $REPOSITORY_URI"

# Prompt for CodeBuild project creation
read -p "Please create a CodeBuild project manually and then press [Enter] to continue..."

# Automatically find the CodeBuild project name
echo "Fetching existing CodeBuild projects..."
CODEBUILD_PROJECTS=$(aws codebuild list-projects --query "projects" --output text)

if [ -z "$CODEBUILD_PROJECTS" ]; then
    echo "No CodeBuild projects found. Please create a CodeBuild project first."
    exit 1
else
    # Display the list of projects and select the first one for simplicity
    echo "Found CodeBuild projects:"
    echo "$CODEBUILD_PROJECTS"
    
    # Retrieve the name of the first project
    CODEBUILD_PROJECT_NAME=$(echo "$CODEBUILD_PROJECTS" | head -n 1)
    echo "Using the first project found: $CODEBUILD_PROJECT_NAME"
fi

# Retrieve the CodeBuild project's IAM role
echo "Retrieving IAM role for the CodeBuild project..."
CODEBUILD_ROLE_ARN=$(aws codebuild batch-get-projects --names "$CODEBUILD_PROJECT_NAME" --query "projects[0].serviceRole" --output text)

if [ -z "$CODEBUILD_ROLE_ARN" ]; then
    echo "Failed to retrieve IAM role for CodeBuild project."
    exit 1
else
    echo "IAM role for CodeBuild project: $CODEBUILD_ROLE_ARN"
fi

# Extract the role name from the ARN
CODEBUILD_ROLE_NAME=$(basename "$CODEBUILD_ROLE_ARN")

# Attach the AmazonEC2ContainerRegistryPowerUser policy to the CodeBuild IAM role
echo "Attaching AmazonEC2ContainerRegistryPowerUser policy to the CodeBuild IAM role..."
aws iam attach-role-policy --role-name "$CODEBUILD_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

if [ $? -ne 0 ]; then
    echo "Failed to attach policy to the IAM role."
    exit 1
else
    echo "Policy attached successfully."
fi

# Start the CodeBuild project using the buildspec.yml from the cloned repo
echo "Starting the CodeBuild project..."
max_retries=3
retry_count=0
timeout=240  # 4 minutes in seconds

while [ $retry_count -le $max_retries ]; do
    # Start the build
    BUILD_ID=$(aws codebuild start-build --project-name "$CODEBUILD_PROJECT_NAME" --query "build.id" --output text)

    if [ -z "$BUILD_ID" ]; then
        echo "Failed to start CodeBuild project."
        exit 1
    else
        echo "Build started successfully with ID: $BUILD_ID"
    fi

    # Check build status
    start_time=$(date +%s)
    while true; do
        sleep 10  # Wait before checking status
        build_status=$(aws codebuild batch-get-builds --ids "$BUILD_ID" --query "builds[0].buildStatus" --output text)
        
        if [ "$build_status" == "SUCCEEDED" ]; then
            echo "Build succeeded."
            exit 0
        elif [ "$build_status" == "FAILED" ]; then
            echo "Build failed."
            break  # Exit inner loop to retry
        elif [ "$build_status" == "IN_PROGRESS" ]; then
            echo "Build is still in progress..."
            continue
        else
            echo "Unknown build status: $build_status"
        fi

        # Check if timeout has been reached
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $timeout ]; then
            echo "Timeout reached while waiting for build status."
            break  # Exit inner loop to retry
        fi
    done
    
    # Increment the retry count
    retry_count=$((retry_count + 1))
    echo "Retrying build... ($retry_count/$max_retries)"

    # Optional: wait before retrying the build
    if [ $retry_count -le $max_retries ]; then
        sleep 5  # Optional delay before next retry
    fi
done

echo "Maximum retries reached. Build failed."
exit 1