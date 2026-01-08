resource "aws_internet_gateway" "narre-igw" {
  vpc_id = aws_vpc.vpc_narre_main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_narre_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.narre-igw.id
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.sub_public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.sub_public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table For NAT instance

resource "aws_route_table" "private_rt_nat" {
  vpc_id = aws_vpc.vpc_narre_main.id

  tags = {
    Name = "private-rt-nat"
  }
}

resource "aws_route" "private_to_nat_instance" {
  route_table_id         = aws_route_table.private_rt_nat.id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = aws_instance.nat.id
}

resource "aws_route_table_association" "private_1_assoc_nat" {
  subnet_id      = aws_subnet.sub_private_1.id
  route_table_id = aws_route_table.private_rt_nat.id
}

resource "aws_route_table_association" "private_2_assoc_nat" {
  subnet_id      = aws_subnet.sub_private_2.id
  route_table_id = aws_route_table.private_rt_nat.id
}

