resource "aws_internet_gateway" "narre-igw" {
  vpc_id = aws_vpc.vpc_narre_main.id
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc_narre_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.narre-igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub_private_1.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sub_private_2.id
  route_table_id = aws_route_table.public-rt.id
}