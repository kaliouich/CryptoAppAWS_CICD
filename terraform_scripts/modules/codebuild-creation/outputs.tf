output "ecr_repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "AWS ECR Repository URL"
}

output "codebuild_project_arn" {
  value       = aws_codebuild_project.this.arn
  description = "AWS CodeBuild Project ARN"
}