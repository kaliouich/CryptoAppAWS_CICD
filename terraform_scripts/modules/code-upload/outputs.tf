output "clone_url_http" {
  value       = aws_codecommit_repository.this.clone_url_http
  description = "The HTTP URL for cloning the repository"
}
