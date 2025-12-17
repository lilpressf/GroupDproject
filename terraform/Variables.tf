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

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cs3-nca-eks"
}

variable "node_instance_type" {
  description = "EKS worker node instance type"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "EKS node group desired size"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "EKS node group min size"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "EKS node group max size"
  type        = number
  default     = 3
}
