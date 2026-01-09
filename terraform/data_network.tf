# Lookup EXISTING VPC
data "aws_vpc" "vpc_narre_main" {
  filter {
    name   = "tag:Name"
    values = ["vpc_narre_main"]
  }
}

# Public subnets
data "aws_subnet" "sub_public_1" {
  filter {
    name   = "tag:Name"
    values = ["sub_public_1"]
  }
}

data "aws_subnet" "sub_public_2" {
  filter {
    name   = "tag:Name"
    values = ["sub_public_2"]
  }
}

# Private subnets (EKS)
data "aws_subnet" "sub_private_1" {
  filter {
    name   = "tag:Name"
    values = ["sub_private_1"]
  }
}

data "aws_subnet" "sub_private_2" {
  filter {
    name   = "tag:Name"
    values = ["sub_private_2"]
  }
}

# Student subnets
data "aws_subnet" "sub_student_1" {
  filter {
    name   = "tag:Name"
    values = ["sub_student_1"]
  }
}

data "aws_subnet" "sub_student_2" {
  filter {
    name   = "tag:Name"
    values = ["sub_student_2"]
  }
}

data "aws_subnet" "sub_student_3" {
  filter {
    name   = "tag:Name"
    values = ["sub_student_3"]
  }
}

# Database subnets
data "aws_subnet" "sub_database_1" {
  filter {
    name   = "tag:Name"
    values = ["sub_database_1"]
  }
}

data "aws_subnet" "sub_database_2" {
  filter {
    name   = "tag:Name"
    values = ["sub_database_2"]
  }
}
