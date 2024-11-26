#!/bin/bash

# Prompt for AWS credentials and repository details
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
read -p "Enter your AWS Region (e.g., us-east-1): " AWS_REGION
read -p "Enter your existing Git username: " GIT_USERNAME
read -p "Enter the name of the CodeCommit repository: " CODECOMMIT_REPO_NAME
read -p "Enter the GitHub repository URL: " GITHUB_REPO_URL

# Configure AWS CLI
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# Create CodeCommit repository
echo "Creating CodeCommit repository..."
aws codecommit create-repository --repository-name "$CODECOMMIT_REPO_NAME"
echo "CodeCommit repository created: $CODECOMMIT_REPO_NAME"

# Clone the GitHub repository
echo "Cloning the GitHub repository..."
git clone "$GITHUB_REPO_URL" temp-github-repo

# Navigate to the cloned GitHub repository directory
cd temp-github-repo || { echo "Failed to enter directory"; exit 1; }

# Add CodeCommit remote
echo "Adding CodeCommit remote..."
CODECOMMIT_URL="ssh://git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${CODECOMMIT_REPO_NAME}"
git remote add codecommit "$CODECOMMIT_URL"

# Push the code to CodeCommit
echo "Pushing code to CodeCommit..."
git push codecommit

# Clean up
cd .. || { echo "Failed to return to the previous directory"; exit 1; }
rm -rf temp-github-repo

echo "Code has been successfully pushed from GitHub to AWS CodeCommit."
