terraform {
  backend "s3" {
    bucket = "NEEDS TO BE FILLED"
    key    = "NEEDS TO BE FILLED"
    region = "NEEDS TO BE FILLED"
    encrypt = true
  }
}