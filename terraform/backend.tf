terraform {
  backend "s3" {
    bucket = "NEEDS TO BE FILLED"
    key    = "NEEDS TO BE FILLED"
    region = "eu-central-1"
    encrypt = true
  }
}