locals {
  aws_region     = "us-east-1"
  project        = "kodekloud-demo"
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "kk-tf-state-26487"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}


generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "us-east-1"
}
EOF
}

generate "provider_version" {
  path      = "provider_version_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}