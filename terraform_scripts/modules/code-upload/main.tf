## ------------------------  VARIABLES  --------------------------- ##

variable "repo_name" {
  type        = string
  description = "repository name"
}

## ------------------------  MAIN  --------------------------- ##

# create code commit repository
resource "aws_codecommit_repository" "this" {
  repository_name = var.repo_name
}

