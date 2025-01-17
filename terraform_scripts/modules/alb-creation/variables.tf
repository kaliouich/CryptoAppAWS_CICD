variable "aws_region" {
  description = "The AWS region in which resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "ecs_services" {
  description = "List of ECS services with their names, ports, and path patterns"
  type = list(object({
    name         = string
    port         = number
    path_pattern = list(string)  # Add path_pattern to define URL path patterns for each service
  }))
}

variable "codebuild_project_arn" {
  description = "The ARN of the CodeBuild project that builds the application"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which to create resources"
  type        = string
}

variable "alb_security_group_id" {
  description = "The ID of the security group for the ALB"
  type        = string
}

variable "subnets" {
  description = "The IDs of the subnets in which to create resources"
  type        = list(string)
}

variable "alb_name" {
  description = "The name of the ALB"
  type        = string
}