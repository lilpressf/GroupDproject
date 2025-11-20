resource "aws_vpc" "vpc_narre_main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "vpc_narre_main"
  }
}

resource "aws_subnet" "sub_public_1" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "sub_public_1"
  }
}

resource "aws_subnet" "sub_public_2" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "sub_public_2"
  }
}

resource "aws_subnet" "sub_management_1" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "sub_management_1"
  }
}

resource "aws_subnet" "sub_monitoring_1" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "sub_monitoring_1"
  }
}

resource "aws_subnet" "sub_student_1" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "sub_student_1"
  }
}

resource "aws_subnet" "sub_student_2" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "sub_student_2"
  }
}

resource "aws_subnet" "sub_student_3" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "sub_student_3"
  }
}

resource "aws_subnet" "sub_database_1" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "sub_database_1"
  }
}

resource "aws_subnet" "sub_database_2" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "sub_database_2"
  }
}

resource "aws_subnet" "sub_private_1" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "sub_private_1"
  }
}

resource "aws_subnet" "sub_private_2" {
  vpc_id            = aws_vpc.vpc_narre_main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "sub_private_2"
  }
}
