resource "aws_lb" "keycloak_alb" {
  name               = "keycloak-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.keycloak_alb_sg.id]
  subnets            = [
    aws_subnet.sub_public_1.id,
    aws_subnet.sub_public_2.id
  ]
  idle_timeout       = 60

  tags = { Name = "keycloak-alb" }
}

resource "aws_lb_target_group" "keycloak_tg" {
  name        = "keycloak-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_narre_main.id

health_check {
  path = "/health/ready"
  matcher = "200"
  port = "8080"
}

  tags = { Name = "keycloak-tg" }
}

resource "aws_lb_target_group_attachment" "keycloak_attachment" {
  target_group_arn = aws_lb_target_group.keycloak_tg.arn
  target_id        = aws_instance.keycloak.id
  port             = 8080
}

resource "aws_lb_listener" "keycloak_http" {
  load_balancer_arn = aws_lb.keycloak_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak_tg.arn
  }
}

locals {
  keycloak_hostname = aws_lb.keycloak_alb.dns_name
}
