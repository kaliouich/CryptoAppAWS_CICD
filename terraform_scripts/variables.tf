variable "aws_profile" {
  type        = string
  description = "AWS profile to use"
  default     = "default"
}

variable "enabled_modules" {
  type        = any
  default     = { "code_upload" = true }
  description = "Modules to enable (true to enable, false to disable)"
}

variable "repo_name" {
  type        = string
  default     = "fake-crypto-webapp"
  description = "Name of the repository"
}

variable "repo_zip" {
  type        = string
  default     = "../fake-crypto-webapp-project-main.zip"
  description = "Path to the zip file containing the repository code"
}