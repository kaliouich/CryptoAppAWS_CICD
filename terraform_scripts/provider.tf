locals {
  region  = "us-east-1"
  profile = var.aws_profile
}

# aws provider
provider "aws" {
  region  = local.region
  profile = local.profile
}
