resource "aws_lb" "loadbalancer" {
  name               = "Loadbalancer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer-SG.id]
  subnets            = [aws_subnet.sub_private_1.id, aws_subnet.sub_private_2.id]
  idle_timeout       = 60
}

resource "aws_lb_target_group" "LoadbalancerTG" {
  name        = "LoadbalancerTG"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_narre_main.id

  health_check {
    path    = "/"
    matcher = "200-399"
  }
}

resource "aws_lb_target_group_attachment" "web1" {
  target_group_arn = aws_lb_target_group.LoadbalancerTG.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2" {
  target_group_arn = aws_lb_target_group.LoadbalancerTG.arn
  target_id        = aws_instance.web2.id
  port             = 80
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.LoadbalancerTG.arn
  }
}

output "lb_dns_name" {
  value = aws_lb.loadbalancer.dns_name
}