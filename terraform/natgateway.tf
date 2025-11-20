# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.sub_public_1.id

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.narre-igw
  ]
}

