resource "aws_key_pair" "acceskey" {
  key_name   = "acceskey"
  public_key = var.ssh_public_key
}
