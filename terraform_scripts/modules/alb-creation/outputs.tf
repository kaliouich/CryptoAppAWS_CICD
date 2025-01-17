output "target_group_arn" {
  value = aws_lb_target_group.this[*].arn
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "listener_arns" {
  value = aws_lb_listener.this.arn
}