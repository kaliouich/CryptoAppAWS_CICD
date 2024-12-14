# Using repo appspec.yaml
# Student should have the Cloud9 Setup running with the repo downloaded till the progress of the course
# They will prepare the appspec.yml and commit it to the rep
# Creating CodePipeline/ Deploy the application onto ECS using CodePipeline​
# Students should have access to create a CodePipeline that will deploy/update the ECS service.
# We should have ECS cluster running already with the 1st service they had created earlier.



# resource "aws_codedeploy_app" "ecs_deploy" {
#   name             = "${var.project_name}-codedeploy-app"
#   compute_platform = "ECS"
# }

# resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
#   app_name               = aws_codedeploy_app.ecs_deploy.name
#   deployment_group_name  = "${var.project_name}-deployment-group"
#   service_role_arn       = aws_iam_role.codedeploy_role.arn
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

#   ecs_service {
#     cluster_name = var.ecs_cluster_name
#     service_name = var.ecs_service_name
#   }

#   # Load balancer info can be specified here if needed
#   # load_balancer_info {
#   #   target_group_pair_info {
#   #     target_groups {
#   #       name = var.target_group_name
#   #     }
#   #     prod_traffic_route {
#   #       listener_arns = [var.listener_arn]
#   #     }
#   #   }
#   # }

#   # Include any necessary triggers or alarms
# }

# resource "aws_iam_role" "codedeploy_role" {
#   name = "${var.project_name}-codedeploy-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "codedeploy.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy" "codedeploy_policy" {
#   name   = "${var.project_name}-codedeploy-policy"
#   role   = aws_iam_role.codedeploy_role.id
#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ecs:DescribeServices",
#         "ecs:UpdateService",
#         "ecs:DescribeTaskSets",
#         "ecs:UpdateTaskSet",
#         "elasticloadbalancing:DescribeTargetGroups",
#         "elasticloadbalancing:DescribeListeners",
#         "elasticloadbalancing:DescribeRules",
#         "elasticloadbalancing:DescribeLoadBalancers",
#         "cloudwatch:PutMetricAlarm",
#         "cloudwatch:DeleteAlarms",
#         "cloudwatch:DescribeAlarms",
#         "sns:Publish",
#         "s3:GetObject"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_s3_bucket" "codepipeline_artifact_store" {
#   bucket = "${var.project_name}-codepipeline-artifact-store"
#   acl    = "private"
# }

# resource "aws_codepipeline" "ecs_deploy" {
#   name     = "${var.project_name}-ecs-deploy"
#   role_arn = aws_iam_role.codepipeline_role.arn

#   artifact_store {
#     type     = "S3"
#     location = aws_s3_bucket.codepipeline_artifact_store.bucket
#   }

#   stage {
#     name = "Source"
#     action {
#       name             = "Source"
#       category         = "Source"
#       owner            = "AWS"
#       provider         = "CodeCommit"
#       version          = "1"
#       output_artifacts = ["source_output"]

#       configuration = {
#         RepositoryName = var.repository_name
#         BranchName     = "main"
#       }
#     }
#   }

#   stage {
#     name = "Build"
#     action {
#       name             = "Build"
#       category         = "Build"
#       owner            = "AWS"
#       provider         = "CodeBuild"
#       input_artifacts  = ["source_output"]
#       output_artifacts = ["build_output"]
#       version          = "1"

#       configuration = {
#         ProjectName = var.codebuild_project_arn
#       }
#     }
#   }

#   stage {
#     name = "Deploy"
#     action {
#       name            = "Deploy"
#       category        = "Deploy"
#       owner           = "AWS"
#       provider        = "CodeDeploy"
#       input_artifacts = ["build_output"]
#       version         = "1"

#       configuration = {
#         ApplicationName = aws_codedeploy_app.ecs_deploy.name
#         # DeploymentGroupName  = aws_codedeploy_app.ecs_deploy.name

#       }
#     }
#   }
# }
# resource "aws_iam_role" "codepipeline_role" {
#   name = "${var.project_name}-codepipeline-role"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "codepipeline.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# # Add policies to the IAM role as needed
