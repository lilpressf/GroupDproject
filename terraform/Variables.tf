variable "region" {
  description = "AWS Region"
  type = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "zone1" {
  description = "Availability zone for subents"
  type = string
  default = "eu-central-1a"
}

variable "zone2" {
  description = "Availibility zone for subents"
  type = string
  default = "eu-central-1b"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#RDS variables 

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "keycloak_version" {
  description = "Keycloak image tag from quay.io/keycloak/keycloak"
  type        = string
  default     = "24.0.5"
}

variable "keycloak_admin_username" {
  type = string
}

variable "keycloak_admin_password" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  description = "Public SSH key for EC2 access"
  type        = string
}
