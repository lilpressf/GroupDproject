resource "aws_security_group" "SSH-Acces-SG" {
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

resource "aws_security_group" "loadbalancer-SG" {
  name        = "loadbalancerSG"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "Web-SG" {
  name        = "WebSG"
  description = "Allow HTTP from loadbalancer"
  vpc_id      = aws_vpc.vpc_narre_main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer-SG.id]
  }

    ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer-SG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Database-SG" {
    name = "Database-SG"
    description = "Allow connection on port 3306"
  vpc_id = aws_vpc.vpc_narre_main.id

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

resource "aws_security_group" "Monitoring-SG" {
  name = "Monitoring-SG"
  description = "Allow access from and to monitoring subnet to the network"
  vpc_id = aws_vpc.vpc_narre_main.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "Management-SG" {
    name = "Management-SG"
    description = "Allow access from management subnet"
    vpc_id = aws_vpc.vpc_narre_main.id

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [var.vpc_cidr]
    }
}