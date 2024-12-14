variable "aws_region" {
  description = "The AWS region in which resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "The name of the ECS service to update with the deployment"
  type        = string
}

variable "codebuild_project_arn" {
  description = "The ARN of the CodeBuild project that builds the application"
  type        = string
}

variable "ecs_service_port" {
  description = "The port on which the service listens"
  type        = number
  default     = 80
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

#comment to check