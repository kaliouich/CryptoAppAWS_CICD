## ------------------------  VARIABLES  --------------------------- ##

variable "repo_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "repo_url" {
  description = "The URL of the CodeCommit repository"
  type        = string
}

variable "codebuild_role" {
  description = "The IAM role for CodeBuild"
  type        = string
}

## ------------------------  MAIN  --------------------------- ##


# Amazon ECR and create a repository
resource "aws_ecr_repository" "this" {
  name = var.repo_name
}


# Attach CloudWatch Logs log streams for build
# CloudWatch Logs Group for build logs
resource "aws_cloudwatch_log_group" "build_logs" {
  name              = "/aws/codebuild/${var.repo_name}"
  retention_in_days = 1
}

# Setup AWS CodeBuild to push docker image to ECR 
resource "aws_codebuild_project" "this" {
  name          = "codebuild-${var.repo_name}"
  description   = "A sample codebuild project to push docker image to ECR"
  service_role  = var.codebuild_role
  build_timeout = 60

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.this.repository_url
    }
  }

  source {
    type     = "CODECOMMIT"
    location = var.repo_url
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.build_logs.name
      stream_name = "build-log-stream"
    }
    s3_logs {
      status = "DISABLED"
    }
  }
}
