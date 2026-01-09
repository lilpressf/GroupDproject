resource "aws_instance" "keycloak" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.sub_public_1.id
  vpc_security_group_ids      = [aws_security_group.keycloak_public_sg.id, aws_security_group.ssh_acces_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.acceskey.key_name
  tags = { Name = "keycloak-ec2" }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl enable docker && systemctl start docker

              docker pull quay.io/keycloak/keycloak:${var.keycloak_version}

              docker run -d --name keycloak --restart unless-stopped \
                -p 8080:8080 \
                -v /var/keycloak:/opt/keycloak/data \
                -e KEYCLOAK_ADMIN="${var.keycloak_admin_username}" \
                -e KEYCLOAK_ADMIN_PASSWORD="${var.keycloak_admin_password}" \
                quay.io/keycloak/keycloak:${var.keycloak_version} \
                start-dev \
                --health-enabled=true \
                --http-port=8080 \
                --http-host=0.0.0.0 \
                --hostname-strict=false \
                --proxy=passthrough
              EOF
}
