resource "aws_instance" "dev-server" {
    instance_type = "t2.micro"
    ami         = "ami-02cff456777cd"
    
    key_name = aws_key_pair.cerberus-key.key_name
    user_data = file("install-nginx.sh")
    tags = {
      Name = local.instance_name
    }
}
resource "aws_s3_bucket" "falshpoint"  {
    bucket = "project-flashpoint-paradox"
}

resource "aws_key_pair" "cerberus-key" {
  key_name = "cerberus"
  public_key = file("/root/terraform-projects/project-cerberus/.ssh/cerberus.pub")
}

resource "aws_eip" "eip" {
  instance = aws_instance.cerberus.id

  provisioner "local-exec" {
    command = "echo ${aws_eip.eip.public_dns} >> /root/cerberus_public_dns.txt"
  }
}

module "iam_iam-user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.28.0"
  name = "max"
  create_user = true
  create_iam_access_key = false
  create_iam_user_login_profile = false
}

resource "aws_s3_object" "upload_sonic_media" {
  bucket = aws_s3_bucket.sonic_media.id
  key = substr(each.value, 7, length(each.value) - 7)
  source = each.value
  for_each = var.media
}

data "aws_secretsmanager_secret_version" "name" {
  secret_id = "my-database-password"
}

resource "aws_db_instance" "rds-db-instance" {
  allocated_storage    = 20
  storage_type = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = data.aws_secretsmanager_secret_version.name.secret_string
}

resource "aws_vpc" "KK_VPC" {
  cidr_block = "10.0.0/16"
}

module "payroll_app" {
  source  = "../modules/payroll-app"
  app_region = lookup(var.region, terraform.workspace)
  ami = lookup(var.ami, terraform.workspace)
}

module "web_instance" {
  source  = "../modules/ec2_instance"
  ami = "ami-01b799c439fd5516a"
  instance_type = "t2.micro"
  instance_name = "web-instance-2"
}

output "instance_public_ip" {
  value = module.web_instance.instance_public_ip
}

locals {
  instance_name = "${var.project_name}-${var.department}-server"
}