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