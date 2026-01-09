resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.sub_public_1.id
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.acceskey.key_name
  source_dest_check           = false   

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
                sysctl -p /etc/sysctl.conf
                yum install -y iptables-services
                iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                service iptables save
                systemctl enable iptables
              EOF

  tags = { Name = "nat-instance" }
}
