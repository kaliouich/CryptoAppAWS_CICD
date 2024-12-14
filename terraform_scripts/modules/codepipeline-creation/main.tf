variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "repo_name" {
  type        = string
  description = "Name of the repository"
}

variable "ressource_name" {
  type        = string
  description = "Name of the repository"
}

variable "role_arn" {
  type        = string
  description = "Role ARN"
}

variable "source_branch" {
  type        = string
  default     = "master"
  description = "Branch name"
}

resource "aws_codepipeline" "codepipeline" {

  name     = var.ressource_name
  role_arn = var.role_arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = var.repo_name
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      output_artifacts = ["source_output"]
      version          = "1"

      configuration = {
        RepositoryName       = var.repo_name
        BranchName           = var.source_branch
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = var.repo_name
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "codebuild-${var.repo_name}"
      }
    }
  }

  stage {
    name = "DeployECS"

    action {
      name            = "DeployECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      run_order = 2

      configuration = {
        ClusterName       = var.cluster_name
        ServiceName       = var.repo_name
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = "60"
      }
    }
  }
}


resource "random_integer" "priority" {
  min = 1
  max = 5000
  keepers = {
    # Generate a new integer each time we switch to a new listener ARN
    repo_name = var.repo_name
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-${var.repo_name}-${random_integer.priority.result}"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
