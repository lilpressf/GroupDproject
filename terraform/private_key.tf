resource "tls_private_key" "acceskey" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "acceskey" {
  key_name   = "acceskey"
  public_key = tls_private_key.acceskey.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.acceskey.private_key_pem
  filename        = "$downloads/acceskey.pem"
  file_permission = "0400"
}