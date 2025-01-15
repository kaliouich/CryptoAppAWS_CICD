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

variable "project_name" {
  type        = string
  default     = "fake-crypto-app"
  description = "Name of the repository"
}

variable "web_app_repo_name" {
  type        = string
  default     = "fake-crypto-web-app"
  description = "Name of the repository"
}

variable "web_app_repo_zip" {
  type        = string
  default     = "../fake-crypto-web-app-project-main.zip"
  description = "Path to the zip file containing the repository code"
}

variable "login_app_repo_name" {
  type        = string
  default     = "fake-crypto-login-app"
  description = "Name of the repository"
}

variable "login_app_repo_zip" {
  type        = string
  default     = "../fake-crypto-login-app-project-main.zip"
  description = "Path to the zip file containing the repository code"
}
