resource "aws_instance" "web-2" {
    instance_type = var.instance_type
    ami         = var.ami
    tags = {
      Name = var.instance_name
    }
}