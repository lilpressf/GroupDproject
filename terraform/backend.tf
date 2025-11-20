terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-groupd"
    key    = "env/test/terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}