variable "managed_ad_name" {
  description = "FQDN for AWS Managed Microsoft AD"
  type        = string
}

variable "managed_ad_password" {
  description = "Directory admin password"
  type        = string
  sensitive   = true
}

resource "aws_directory_service_directory" "managed_ad" {
  name     = var.managed_ad_name
  password = var.managed_ad_password
  size     = "Small"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = aws_vpc.vpc_narre_main.id
    subnet_ids = [aws_subnet.sub_private_1.id, aws_subnet.sub_private_2.id]
  }

  tags = {
    Name = "managed-ad"
  }
}
