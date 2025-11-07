resource "aws_vpc" "Narrekappe-VPC" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "Narrekappe-VPC"
    } 
}
