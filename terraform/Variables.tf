variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "name" {
  type    = string
  default = "training-platform"
}

variable "db_name" {
  type    = string
  default = "training"
}

variable "instance_type_easy" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_medium" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_hard" {
  type    = string
  default = "t3.micro"
}
