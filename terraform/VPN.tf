resource "aws_instance" "vpn" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.acceskey.key_name
  subnet_id              = aws_subnet.sub_public_1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_acces_sg.id
  ]

    tags = {
        Name = "VPN-Instance"
    }
}
