resource "aws_vpc" "Narrekappe-VPC" {
    cidr_block = var.vpc_cidr

    tags = {
        Name = "Narrekappe-VPC"
    } 
}

resource "aws_subnet" "Public_Subent_1" {
    vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "Public_Subnet_1"
  }
}

resource "aws_subnet" "Public_Subent_2" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.2.10/24"
  availability_zone = var.zone2

  tags = {
    Name = "Public_Subnet_2"
  }
}

resource "aws_subnet" "Management_Subent" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.3.10/24"
  availability_zone = var.zone1

  tags = {
    Name = "Management_Subent"
  }
}
resource "aws_subnet" "Monitoring_Subent" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.4.10/24"
  availability_zone = var.zone1

  tags = {
    Name = "Monitoring_Subet"
  }
}
resource "aws_subnet" "Student_Subnet_1" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "Student_Subent_1"
  }
}
resource "aws_subnet" "Student_Subnet_2" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "Student_Subent_2"
  }
}
resource "aws_subnet" "Student_Subnet_3" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "Student_Subnet_3"
  }
}
resource "aws_subnet" "Database_Subent_1" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        =  "10.0.20.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "Database_Subent_1"
  }
}
resource "aws_subnet" "Database_Subent_2" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "Database_Subent_2"
  }
}
resource "aws_subnet" "Private_Subnet_1" {
    vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = var.zone1

  tags = {
    Name = "Private_Subent_1"
  }
}
resource "aws_subnet" "Private_Subnet_2" {
      vpc_id            = aws_vpc.Narrekappe-VPC.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "Private_Subnet_2"
  }
}