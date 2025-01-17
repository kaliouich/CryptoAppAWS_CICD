data "aws_caller_identity" "current" {}

locals {
  project_name = var.project_name
  repo_name    = var.web_app_repo_name
  repo_zip     = var.web_app_repo_zip
  repo_name2   = var.login_app_repo_name
  repo_zip2    = var.login_app_repo_zip
  account_id   = data.aws_caller_identity.current.account_id
  cluster_name = "khalil-lab-cluster"

  # Enable flags based on the counter.  More descriptive names used here.
  enable_code_upload       = lookup(var.enabled_modules, "code_upload", false) == true ? 1 : 0
  enable_codebuild_creation = (local.enable_code_upload * (lookup(var.enabled_modules, "codebuild_creation", false) == true ? 1 : 0)) == 1 ? 1 : 0
  enable_ecs_service_creation = (local.enable_codebuild_creation * (lookup(var.enabled_modules, "ecs_service_creation", false) == true ? 1 : 0)) == 1 ? 1 : 0
  enable_alb_creation        = (local.enable_codebuild_creation * (lookup(var.enabled_modules, "alb_creation", false) == true ? 1 : 0)) == 1 ? 1 : 0
  enable_circuit_breaker     = (local.enable_alb_creation * (lookup(var.enabled_modules, "circuit_breaker", false) == true ? 1 : 0)) == 1 ? 1 : 0
  enable_codepipeline_creation = (local.enable_ecs_service_creation * (lookup(var.enabled_modules, "codepipeline_creation", false) == true ? 1 : 0)) == 1 ? 1 : 0
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


resource "aws_security_group" "default" {
  name        = "khalil-lab-sg"
  vpc_id      = data.aws_vpc.default.id
  description = "khalil-lab-sg"

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

#permissions for codebuild role to run pipeline
resource "aws_iam_policy" "codebuild_policy" {
  name        = "CodeBuildPolicy-${local.repo_name}"
  description = "Policy for CodeBuild role to access S3 and IAM"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "iam:PassRole",
          "s3:PutObject"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild_policy_login" {
  name        = "CodeBuildPolicy-${local.repo_name2}"
  description = "Policy for CodeBuild role to access S3 and IAM"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Statement1",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "iam:PassRole",
          "s3:PutObject"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# Attach AmazonEC2ContainerRegistryPowerUser policy to the role
resource "aws_iam_policy_attachment" "AmazonEC2ContainerRegistryPowerUser" {
  name       = "codebuild-policy-attachment-${local.repo_name}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_policy_attachment" "AWSElasticBeanstalkRoleECS" {
  name       = "codebuild-policy-attachment-${local.repo_name}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkRoleECS"
}

resource "aws_iam_policy_attachment" "CloudWatchFullAccess" {
  name       = "codebuild-policy-attachment-${local.repo_name}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_policy_attachment" "AWSCodeCommitReadOnly" {
  name       = "codebuild-policy-attachment-${local.repo_name}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}

# Attach AmazonEC2ContainerRegistryPowerUser policy to the role
resource "aws_iam_policy_attachment" "AmazonEC2ContainerRegistryPowerUserLogin" {
  name       = "codebuild-policy-attachment-${local.repo_name2}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_policy_attachment" "AWSElasticBeanstalkRoleECSLogin" {
  name       = "codebuild-policy-attachment-${local.repo_name2}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkRoleECS"
}

resource "aws_iam_policy_attachment" "CloudWatchFullAccessLogin" {
  name       = "codebuild-policy-attachment-${local.repo_name2}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_policy_attachment" "AWSCodeCommitReadOnlyLogin" {
  name       = "codebuild-policy-attachment-${local.repo_name2}"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}

# CodePipeline Role

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role-crypto-web-app"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "codepipeline_role_login" {
  name = "codepipeline-role-crypto-login-app"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "codepipeline_custom_policy" {
  name = "CodepipelineCustomPolicy"
  path = "/"
  policy = jsonencode({
    "Statement" = [
      {
        "Action" = [
          "iam:PassRole"
        ],
        "Resource" = "*",
        "Effect"   = "Allow",
        "Condition" = {
          "StringEqualsIfExists" = {
            "iam:PassedToService" = [
              "cloudformation.amazonaws.com",
              "elasticbeanstalk.amazonaws.com",
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        "Action" = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "codestar-connections:UseConnection"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "ecs:*"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "opsworks:CreateDeployment",
          "opsworks:DescribeApps",
          "opsworks:DescribeCommands",
          "opsworks:DescribeDeployments",
          "opsworks:DescribeInstances",
          "opsworks:DescribeStacks",
          "opsworks:UpdateApp",
          "opsworks:UpdateStack"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Action" = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ],
        "Resource" = "*",
        "Effect"   = "Allow"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "devicefarm:ListProjects",
          "devicefarm:ListDevicePools",
          "devicefarm:GetRun",
          "devicefarm:GetUpload",
          "devicefarm:CreateUpload",
          "devicefarm:ScheduleRun"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "servicecatalog:ListProvisioningArtifacts",
          "servicecatalog:CreateProvisioningArtifact",
          "servicecatalog:DescribeProvisioningArtifact",
          "servicecatalog:DeleteProvisioningArtifact",
          "servicecatalog:UpdateProduct"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "cloudformation:ValidateTemplate"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "ecr:DescribeImages"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "states:DescribeExecution",
          "states:DescribeStateMachine",
          "states:StartExecution"
        ],
        "Resource" = "*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "appconfig:StartDeployment",
          "appconfig:StopDeployment",
          "appconfig:GetDeployment"
        ],
        "Resource" = "*"
      }
    ],
    "Version" = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_custom_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "codepipeline_custom_policy_attachment_login" {
  role       = aws_iam_role.codepipeline_role_login.name
  policy_arn = aws_iam_policy.codepipeline_custom_policy.arn
}

# Create IAM role for ECS Task Execution
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create IAM role for ECS Instance
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-cluster-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecs-${local.cluster_name}"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_policy_attachment" "ecs_instance_role_attachment" {
  name       = "ecs-instance-role-attachment"
  roles      = [aws_iam_role.ecs_instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

module "code_upload" {
  count = local.enable_code_upload

  source    = "./modules/code-upload"
  repo_name = local.repo_name
}

module "code_upload_login" {
  count = local.enable_code_upload

  source    = "./modules/code-upload"
  repo_name = local.repo_name2
}

resource "null_resource" "upload_code" {
  count = local.enable_code_upload

  depends_on = [module.code_upload]

  provisioner "local-exec" {
    command = <<-EOT
      set -ex
      export AWS_DEFAULT_REGION=${local.region}
      export AWS_PROFILE=${local.profile}
      export ACCOUNT_ID=${local.account_id}
      export DIR_PATH="./assets/${local.repo_name}"

      mkdir -p assets
      cd assets
      git clone codecommit::${local.region}://${local.repo_name} || echo "Directory exists"

      unzip -o ${local.repo_zip} -d demo
      cp -r demo/* ${local.repo_name};rm -rf demo
      cd -

      python3 "./template_replace.py" || exit 1

      cd $DIR_PATH
      git config user.email "khalil@cloud.com"
      git config user.name "khalil"
      git add .

      set +ex
      git commit -m "Initial commit"
      git push
      rm -rf *
      cd -
    EOT
  }

    provisioner "local-exec" {
    command = <<-EOT
      set -ex
      export AWS_DEFAULT_REGION=${local.region}
      export AWS_PROFILE=${local.profile}
      export ACCOUNT_ID=${local.account_id}
      export DIR_PATH="./assets/${local.repo_name2}"

      mkdir -p assets
      cd assets
      git clone codecommit::${local.region}://${local.repo_name2} || echo "Directory exists"

      unzip -o ${local.repo_zip2} -d demo
      cp -r demo/* ${local.repo_name2};rm -rf demo
      cd -

      python3 "./template_replace2.py" || exit 1

      cd $DIR_PATH
      git config user.email "khalil@cloud.com"
      git config user.name "khalil"
      git add .

      set +ex
      git commit -m "Initial commit"
      git push 
      rm -rf *
      cd -
    EOT
  }
}

module "codebuild_creation" {
  count      = local.enable_codebuild_creation
  depends_on = [module.code_upload]

  source         = "./modules/codebuild-creation" # Assumed new name for the module
  repo_name      = local.repo_name
  repo_url       = module.code_upload[0].clone_url_http # Adjust if clone_url_http is not available in code_upload module
  codebuild_role = aws_iam_role.codebuild_role.arn
}

module "codebuild_creation_login" {
  count      = local.enable_codebuild_creation
  depends_on = [module.code_upload]

  source         = "./modules/codebuild-creation" # Assumed new name for the module
  repo_name      = local.repo_name2
  repo_url       = module.code_upload_login[0].clone_url_http # Adjust if clone_url_http is not available in code_upload module
  codebuild_role = aws_iam_role.codebuild_role.arn
}

module "ecs_service_creation" {
  count      = local.enable_ecs_service_creation
  depends_on = [module.codebuild_creation]
  source     = "./modules/ecs-service-creation"
  
  services = [
    {
      name            = local.repo_name
      container_image = "${module.codebuild_creation[0].ecr_repository_url}:latest"
      container_port  = 5000
      desired_count   = 1
    },
    {
      name            = local.repo_name2
      container_image = "${module.codebuild_creation_login[0].ecr_repository_url}:latest"
      container_port  = 8080
      desired_count   = 1
    },
    # Add more services as needed
    # {
    #   name            = "second-service"
    #   container_image = "second-image:latest"
    #   container_port  = 8080
    #   desired_count   = 2
    # }
  ]
  
  cluster_name           = local.cluster_name
  aws_region             = local.region
  security_group_id      = aws_security_group.default.id
  create_tg              = local.enable_alb_creation == 1 ? true : false
  target_group_arn       = local.enable_alb_creation == 1 ? module.alb_creation[0].target_group_arn : [""]
  task_execution_role    = aws_iam_role.ecsTaskExecutionRole.arn
  enable_circuit_breaker = local.enable_circuit_breaker == 1 ? true : false
  instance_profile_name  = aws_iam_instance_profile.ecs_instance_role.name
}

module "alb_creation" {
  count      = local.enable_alb_creation
  depends_on = [module.codebuild_creation]

  source = "./modules/alb-creation"  # Assumed new name for the module

  aws_region            = local.region
  codebuild_project_arn = module.codebuild_creation[0].codebuild_project_arn # Adjust if codebuild_project_arn is not available in codebuild_creation module
  ecs_cluster_name      = local.cluster_name
  ecs_services = [
    {
      name         = local.repo_name
      port         = 5000
      path_pattern = ["/api/*"]  # Example path pattern for the first service
    },
    {
      name         = local.repo_name2
      port         = 8080
      path_pattern = ["/login/*"]  # Example path pattern for the second service
    }
  ]
  vpc_id                = data.aws_vpc.default.id
  alb_security_group_id = aws_security_group.default.id
  subnets               = data.aws_subnets.default.ids
  alb_name              = "alb"
}

module "codepipeline_creation" {
  count      = local.enable_codepipeline_creation
  depends_on = [module.ecs_service_creation]

  source = "./modules/codepipeline-creation"

  cluster_name = local.cluster_name
  repo_name    = local.repo_name
  ressource_name = "crypto-app"
  role_arn     = aws_iam_role.codepipeline_role.arn
}

module "codepipeline_creation_login" {
  count      = local.enable_codepipeline_creation
  depends_on = [module.ecs_service_creation]

  source = "./modules/codepipeline-creation"

  cluster_name = local.cluster_name
  repo_name    = local.repo_name2
  ressource_name = "crypto-app-login"
  role_arn     = aws_iam_role.codepipeline_role_login.arn
}