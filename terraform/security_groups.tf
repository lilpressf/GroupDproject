resource "aws_security_group" "ssh_acces_sg" {
  name        = "Allow-SSH"
  description = "Allow connection on port 22"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AllowSSHSG"
  }
}

resource "aws_security_group" "loadbalancer_sg" {
  name        = "loadbalancerSG"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "keycloak_alb_sg" {
  name        = "keycloak-alb-sg"
  description = "Allow HTTP to Keycloak ALB"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "keycloak-alb-sg"
  }
}

resource "aws_security_group" "keycloak_sg" {
  name        = "keycloak-ec2-sg"
  description = "Allow Keycloak traffic from ALB"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.keycloak_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "keycloak-ec2-sg"
  }
}


resource "aws_security_group" "web_sg" {
  name        = "WebSG"
  description = "Allow HTTP from loadbalancer"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database_sg" {
  name        = "Database-SG"
  description = "Allow connection on port 3306"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "monitoring_sg" {
  name        = "Monitoring-SG"
  description = "Allow access from and to monitoring subnet to the network"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "management_sg" {
  name        = "Management-SG"
  description = "Allow access from management subnet"
  vpc_id      = aws_vpc.vpc_narre_main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "nat_sg" {
  name        = "nat-instance-sg"
  description = "Allow outbound internet for private subnets"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat-instance-sg"
  }
}

