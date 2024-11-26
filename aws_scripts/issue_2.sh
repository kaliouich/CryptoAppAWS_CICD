#!/bin/bash

# Prompt for AWS credentials and input
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
read -p "Enter your AWS Region (e.g., us-east-1): " AWS_REGION
read -p "Enter your GitHub repository (e.g., user/repo): " GITHUB_REPO
read -p "Enter the name for the CodeBuild project: " CODEBUILD_PROJECT_NAME

# Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# List IAM roles and prompt for selection
echo "Fetching IAM roles..."
ROLE_LIST=$(aws iam list-roles --query "Roles[*].RoleName" --output text)
echo "Available IAM Roles:"
echo "$ROLE_LIST"

read -p "Enter the name of the IAM role to use: " ROLE_NAME

# Fetch the full ARN of the selected role
CODEBUILD_ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query "Role.Arn" --output text)

if [ -z "$CODEBUILD_ROLE_ARN" ]; then
    echo "Role '$ROLE_NAME' not found. Exiting."
    exit 1
fi

echo "Using IAM Role ARN: $CODEBUILD_ROLE_ARN"

# Create CodeBuild project
echo "Creating CodeBuild project..."
response=$(aws codebuild create-project --name "$CODEBUILD_PROJECT_NAME" \
    --source "{
        \"type\": \"GITHUB\",
        \"location\": \"https://github.com/$GITHUB_REPO\"
    }" \
    --artifacts "{\"type\": \"NO_ARTIFACTS\"}" \
    --environment "{
        \"computeType\": \"BUILD_GENERAL1_SMALL\",
        \"image\": \"aws/codebuild/standard:5.0\",
        \"type\": \"LINUX_CONTAINER\"
    }" \
    --service-role "$CODEBUILD_ROLE_ARN" \
    --timeout-in-minutes 60)

if [ $? -eq 0 ]; then
    echo "CodeBuild project '$CODEBUILD_PROJECT_NAME' created successfully."
else
    echo "Failed to create CodeBuild project. Response: $response"
    exit 1
fi