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
              set -euo pipefail

              yum update -y
              amazon-linux-extras install docker -y
              amazon-linux-extras install nginx1 -y
              systemctl enable docker && systemctl start docker

              mkdir -p /var/keycloak
              chown -R 1000:1000 /var/keycloak

              mkdir -p /etc/nginx/ssl /etc/nginx/conf.d
              if [ ! -f /etc/nginx/ssl/keycloak.key ]; then
                openssl req -x509 -nodes -days 365 \
                  -newkey rsa:2048 \
                  -keyout /etc/nginx/ssl/keycloak.key \
                  -out /etc/nginx/ssl/keycloak.crt \
                  -subj "/CN=keycloak-selfsigned"
              fi

              cat >/etc/nginx/conf.d/keycloak.conf <<'NGINX'
              server {
                listen 443 ssl;
                server_name _;

                ssl_certificate     /etc/nginx/ssl/keycloak.crt;
                ssl_certificate_key /etc/nginx/ssl/keycloak.key;

                location / {
                  proxy_pass http://127.0.0.1:8080;
                  proxy_http_version 1.1;
                  proxy_set_header Connection "";
                  proxy_set_header Host $host;
                  proxy_set_header X-Forwarded-Host $host;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto https;
                  proxy_set_header X-Forwarded-Port 443;
                  proxy_buffering off;
                  proxy_read_timeout 300;
                }
              }
NGINX

              rm -f /etc/nginx/conf.d/default.conf
              systemctl enable nginx
              systemctl restart nginx

              docker pull quay.io/keycloak/keycloak:${var.keycloak_version}

              docker rm -f keycloak || true
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
                --proxy-headers=xforwarded
              EOF
}
