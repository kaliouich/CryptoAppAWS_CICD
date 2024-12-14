
resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = [for subnet in var.subnets : subnet]

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }
}

resource "aws_lb_target_group" "this" {

  name        = var.ecs_service_name
  port        = var.ecs_service_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "this" {
  lifecycle {
    create_before_destroy = true
  }

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  depends_on = [aws_lb_target_group.this]
}
