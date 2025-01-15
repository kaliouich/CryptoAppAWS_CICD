# Setup ECR Section - 05 – You can combine this into 2 or 2 lab sections 
# Creating of ECS cluster
# Students should have full access to create an ECS cluster- Fargate is what we will use 
# Deploy the docker image manually using Console on ECS 
# ECS Cluster should be ready already and students will now create a task definition and service.
# After which will deploy the service on AWS ECS all via console 
# Terraform configuration for creating an ECS Cluster and related resources


## ------------------- VARIABLES ------------------- ##
variable "cluster_name" {
  type        = string
  description = "ECS Cluster Name"
}

variable "cluster_capacity" {
  type        = number
  default     = 3
  description = "ECS Cluster Capacity"
}

variable "desired_count" {
  type        = number
  default     = 2
  description = "Desired Count"
}

variable "enable_circuit_breaker" {
  type        = bool
  default     = false
  description = "Enable Circuit Breaker"
}

variable "service_name" {
  type        = string
  description = "ECS Service Name"
}

variable "container_image" {
  type        = string
  description = "Docker Image"
}

variable "container_port" {
  type        = number
  default     = 80
  description = "Container Port"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "security_group_id" {
  type        = string
  description = "Security Group ID"
}

variable "create_tg" {
  type        = bool
  default     = false
  description = "Create Target Group"
}

variable "target_group_arn" {
  type        = string
  default     = ""
  description = "Target Group ARN"
}

variable "instance_type" {
  type        = string
  default     = "t3a.micro"
  description = "EC2 instance type for the ECS cluster"
}

variable "task_execution_role" {
  type        = string
  description = "Task Execution Role"
}

variable "instance_profile_name" {
  type        = string
  description = "Instance Profile Name"
}

## ------------------- DATA SOURCES ------------------- ##
# data "aws_iam_role" "this" {
#   name = "ecsTaskExecutionRole"
# }

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# amazon linux2 ami for ECS of type hvm and ebs amd64
data "aws_ami" "amazon_linux_2" {
  # amzn2-ami-ecs-kernel-5.10-hvm-2.0.20240409-x86_64-ebs
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

## ----------------------------------------------- MAIN ---------------------------------------------- ##

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "deployer" {
  key_name   = "fake-crypto-web-app-cluster-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}


## ------------------- ECS CLUSTER CREATION ------------------- ##


resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 1
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}



resource "aws_launch_template" "ecs" {
  name_prefix = "launch-template-${var.cluster_name}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 30
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  iam_instance_profile {
    name = var.instance_profile_name
  }
  # metadata_options {
  #   http_tokens = "required"
  # }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ECSInstance"
    }
  }

  instance_type          = var.instance_type
  image_id               = data.aws_ami.amazon_linux_2.id
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(<<-EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config;
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config;
EOF
  )

}

resource "aws_autoscaling_group" "ecs" {
  name = var.cluster_name

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = var.cluster_capacity
  desired_capacity = var.desired_count

  availability_zones = [
    "${var.aws_region}a",
    #"${var.aws_region}b",
    #"${var.aws_region}c",
    #"${var.aws_region}d",
    #"${var.aws_region}f"
  ]

  #vpc_zone_identifier = [data.aws_subnets.default.ids[0]]
}

resource "aws_ecs_capacity_provider" "ecs" {
  name = "${var.cluster_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [aws_ecs_capacity_provider.ecs.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs.name
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.task_execution_role

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_name}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "EC2"


  # network_configuration {
  #   subnets          = data.aws_subnets.default.ids
  #   security_groups  = [var.security_group_id]
  #   assign_public_ip = true
  # }

  dynamic "deployment_controller" {
    for_each = var.enable_circuit_breaker == true ? [1] : []
    content {
      type = "ECS"
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.enable_circuit_breaker == true ? [1] : []
    content {
      enable   = true
      rollback = true
    }
  }

  dynamic "load_balancer" {
    for_each = var.create_tg == true ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  depends_on = [aws_autoscaling_group.ecs]
}
