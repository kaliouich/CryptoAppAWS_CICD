output "ecs_cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "AWS ECS Cluster Name"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.this.arn
  description = "AWS ECS Cluster ARN"
}

output "ecs_service_names" {
  value       = aws_ecs_service.services[*].name
  description = "List of AWS ECS Service Names"
}

output "ecs_service_arns" {
  value       = aws_ecs_service.services[*].id
  description = "List of AWS ECS Service ARNs"
}

output "container_ports" {
  value       = [for s in var.services : s.container_port]
  description = "List of Container Ports"
}

output "task_definition_arns" {
  value       = aws_ecs_task_definition.services[*].arn
  description = "List of Task Definition ARNs"
}