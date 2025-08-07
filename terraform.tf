terraform {
  backend "s3" {
    bucket = "remote-state"
    key    = "terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "my-lock-table"
    encrypt = true
  }
}