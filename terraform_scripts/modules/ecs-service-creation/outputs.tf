output "ecs_cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "AWS ECS Cluster Name"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "AWS ECS Cluster ARN"
}

output "ecs_service_name" {
  value       = aws_ecs_service.this.name
  description = "AWS ECS Service Name"
}

output "container_port" {
  value       = var.container_port
  description = "Container Port"
}
