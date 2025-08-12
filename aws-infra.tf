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

resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "AppVPC"
  }
}

resource "aws_subnet" "app_subnet_1" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "AppSubnet1"
  }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "AppSubnet2"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "WebTrafficSG"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.app_vpc.id

  dynamic "ingress" {
    for_each = var.tcp_port_list
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebTrafficSG"
  }
}

resource "aws_network_interface" "nw_interface1" {
  subnet_id       = aws_subnet.app_subnet_1.id
  security_groups = [aws_security_group.app_sg.id]
  tags = {
    Name = "nw_interface1"
  }
}

resource "aws_network_interface" "nw_interface2" {
  subnet_id       = aws_subnet.app_subnet_2.id
  security_groups = [aws_security_group.app_sg.id]
  tags = {
    Name = "nw_interface2"
  }
}

resource "aws_internet_gateway" "AppInternetGateway" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "AppInternetGateway"
  }
}

resource "aws_route_table" "AppRouteTable" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "AppRouteTable"
  }
}

output "route_table_id" {
  value = aws_route_table.AppRouteTable.id
}

resource "aws_route" "allow_internet_access" {
  route_table_id         = aws_route_table.AppRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.AppInternetGateway.id
}

resource "aws_route_table_association" "AssociateAppRouteTableSubnet1" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.AppRouteTable.id
}

resource "aws_route_table_association" "AssociateAppRouteTableSubnet2" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.AppRouteTable.id
}

resource "aws_eip" "eip1" {
  network_interface = aws_network_interface.nw_interface1.id
}

resource "aws_eip" "eip2" {
  network_interface = aws_network_interface.nw_interface2.id
}

resource "aws_instance" "instance1" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  key_name = aws_key_pair.my-ec2-key.key_name
  network_interface {
    network_interface_id = aws_network_interface.nw_interface1.id
    device_index         = 0
  }
  tags = {
    Name = "WebServer1"
  }
}

resource "aws_instance" "instance2" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  key_name = aws_key_pair.my-ec2-key.key_name
  network_interface {
    network_interface_id = aws_network_interface.nw_interface2.id
    device_index         = 0
  }
  tags = {
    Name = "WebServer2"
  }
}

resource "aws_key_pair" "my-ec2-key" {
  key_name = "my-ec2-key"
  public_key = file("/root/.ssh/my-ec2-key.pub")
}

output "instance1_id" {
  value = aws_instance.instance1.id
}

output "instance2_id" {
  value = aws_instance.instance2.id
}

resource "aws_db_subnet_group" "app-db-subnet-group" {
  subnet_ids = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]

  tags = {
    Name = "app-db-subnet-group"
  }
}

resource "aws_db_instance" "AppDatabase" {
  engine     = "mysql"
  engine_version = "8.0.33"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_name = "appdatabase"
  username = "admin"
  password = "db*pass123"
  publicly_accessible = true
  db_subnet_group_name = aws_db_subnet_group.app-db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  tags = {
    Name = "AppDatabase"
  }
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

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "codepipeline_policy"
  description = "Policy for CodePipeline to access S3 and other resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "codecommit:*",
          "codebuild:*",
          "elasticbeanstalk:*",
          "cloudformation:*",
          "autoscaling:*",
          "ec2:*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
  
}

resource "aws_iam_role" "iam_role_for_codepipeline" {
  name = "iam_role_for_codepipeline"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  }) 
}

resource "aws_iam_policy_attachment" "attach_role_policy" {
  name       = "attach_role_policy"
  roles      = [aws_iam_role.iam_role_for_codepipeline.name]
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

data "aws_s3_bucket" "artifact_store" {
  bucket = "terraform-web-app-bucket-*"
}

resource "aws_codepipeline" "web_app_pipeline" {
  name = "terraform-web-app-pipeline"
  role_arn = aws_iam_role.iam_role_for_codepipeline.arn
  artifact_store {
    type     = "S3"
    location = "terraform-web-app-bucket-f8b935ae5f5c"
  }
  stage {
      name = "Source"

      action {
        name             = "Source"
        category         = "Source"
        owner            = "ThirdParty"
        provider         = "Github"
        version          = "1"
        output_artifacts = ["source_output"]

        configuration = {
          owner = "<USERNAME>"
          repo  = "terraform-infra"
          oauth_token = "<ACCESS_TOKEN>"
          BranchName       = "main"
        }
      }
    }

    stage {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ElasticBeanstalk"
        input_artifacts = ["source_output"]
        version         = "1"

        configuration = {
          ApplicationName = "terraform-web-app"
          EnvironmentName = "devm"
        }
      }
    }
}

