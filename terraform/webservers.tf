locals {
  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable nginx1
    yum install -y nginx mysql wget tar

    systemctl start nginx
    systemctl enable nginx
  EOT
}
# aws_security_group moet nog aangepast worden
resource "aws_instance" "web1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sub_private_1.id
  private_ip             = "10.0.5.1"
  vpc_security_group_ids = [aws_security_group.Web-SG.id]
  key_name               = "Project1"
  user_data              = local.user_data
  tags = { Name = "lab-g1-web-easy-01" }
}

resource "aws_instance" "web2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sub_private_2.id
  private_ip             = "10.0.6.1"
  vpc_security_group_ids = [aws_security_group.Web-SG.id]
  key_name               = "Project1"
  user_data              = local.user_data
  tags = { Name = "lab-g1-web-easy-02" }
}
