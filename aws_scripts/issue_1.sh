#!/bin/bash

# Prompt for AWS credentials
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
read -p "Enter your AWS Region (e.g., us-east-1): " AWS_REGION
read -p "Enter your Git username: " GIT_USERNAME
read -p "Enter the name of the CodeCommit repository: " CODECOMMIT_REPO_NAME

# Configure AWS CLI
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# Create Git credentials for CodeCommit
echo "Creating IAM user for Git credentials..."
USER_POLICY="{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
        {
            \"Effect\": \"Allow\",
            \"Action\": [
                \"codecommit:GitPull\",
                \"codecommit:GitPush\"
            ],
            \"Resource\": \"*\"
        }
    ]
}"

USER_NAME="${GIT_USERNAME}-git-user"

# Create IAM user
aws iam create-user --user-name "$USER_NAME"

# Attach policy to the IAM user
aws iam put-user-policy --user-name "$USER_NAME" --policy-name "CodeCommitAccessPolicy" --policy-document "$USER_POLICY"

# Create access key for the user
ACCESS_KEY=$(aws iam create-access-key --user-name "$USER_NAME" --query "AccessKey.[AccessKeyId, SecretAccessKey]" --output text)

read ACCESS_KEY_ID ACCESS_SECRET <<<"$ACCESS_KEY"

echo "IAM user '$USER_NAME' created with Git credentials:"
echo "Access Key ID: $ACCESS_KEY_ID"
echo "Secret Access Key: $ACCESS_SECRET"

# Create CodeCommit repository
echo "Creating CodeCommit repository..."
aws codecommit create-repository --repository-name "$CODECOMMIT_REPO_NAME"
echo "CodeCommit repository created: $CODECOMMIT_REPO_NAME"

echo "You can now use the Access Key ID and Secret Access Key to configure Git credentials for AWS CodeCommit."
