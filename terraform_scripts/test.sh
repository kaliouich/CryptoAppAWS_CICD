terraform destroy -auto-approve ; terraform apply -auto-approve

# export AWS_REGION=us-east-1
# export AWS_PROFILE=kk-kml-lab-switch

# export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# export DIR_PATH="./assets/my-repo"

# python3 template_replace.py