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