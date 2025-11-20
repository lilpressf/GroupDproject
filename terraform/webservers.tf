locals {
  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable nginx1
    yum install -y nginx mysql wget tar

    systemctl start nginx
    systemctl enable nginx

    MY_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

    echo "<h1>Welkom bij mijn website!</h1>" > /usr/share/nginx/html/index.html
    echo "<p>Deze webserver IP: $MY_IP</p>" >> /usr/share/nginx/html/index.html
  EOT
}
# aws_security_group moet nog aangepast worden
resource "aws_instance" "web1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sub_private_1.id
  vpc_security_group_ids = [aws_security_group.Web-SG.id]
  user_data              = local.user_data
  tags = { Name = "lab-g1-web-easy-01" }
}

resource "aws_instance" "web2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sub_private_2.id
  vpc_security_group_ids = [aws_security_group.Web-SG.id]
  user_data              = local.user_data
  tags = { Name = "lab-g1-web-easy-02" }
}
