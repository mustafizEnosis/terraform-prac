resource "aws_instance" "web-2" {
    instance_type = var.instance_type
    ami         = var.ami
    tags = {
      Name = var.instance_name
    }
    provisioner "remote-exec" {
      inline = [ "sudo yum update -y",
                  "sudo yum install -y nginx",
                  "sudo systemctl start nginx",
                  "sudo systemctl enable nginx" ]
    }

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("/root/my-terraform-key.pem")
      host = self.public_ip
    }
}

# Configure the GitHub provider
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# The provider block tells Terraform how to communicate with GitHub.
# The token is read from the GITHUB_TOKEN environment variable.
provider "github" {
  token = "<ACCESS_TOKEN>"
}

# Define the repository resource
resource "github_repository" "github_repo" {
  name        = "terraform-infra"
  description = "This repository was created using Terraform."
  visibility  = "public" # Can also be "private"
  auto_init   = true     # Creates a default README.md file
}

# Define an output to easily find the repository URL after creation
output "repository_clone_url_ssh" {
  value = github_repository.github_repo.ssh_clone_url
  description = "The URL of the newly created GitHub repository."
}