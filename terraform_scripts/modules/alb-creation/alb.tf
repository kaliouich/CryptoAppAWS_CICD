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
  count       = length(var.ecs_services)
  name        = "${var.alb_name}-tg-${var.ecs_services[count.index].name}"
  port        = var.ecs_services[count.index].port
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
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  depends_on = [aws_lb_target_group.this]
}

resource "aws_lb_listener_rule" "this" {
  count        = length(var.ecs_services)
  listener_arn = aws_lb_listener.this.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/${var.ecs_services[count.index].name}/*"]
    }
  }
}