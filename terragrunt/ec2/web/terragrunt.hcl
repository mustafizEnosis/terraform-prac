terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws//?version=5.6.1"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "app_dependency" {
  name = "vpc"
  config_path = "../../vpc"
}

inputs = {
  name = "${include.root.locals.project}"
  ami = "${include.root.locals.ami}"
  instance_type = "${include.root.locals.instance_type}"
  subnet_id = "${dependency.vpc.outputs.public_subnets[0]}"
}

download_dir = "../.terragrunt-config"

prevent_destroy = true

iam_role = "arn:aws:iam::590183739792:role/KodeKloud-Terragrunt-Role"

terraform_binary = "/root/terraform-stack/terraform_1.8.2"
terraform_version_constraint = "= 1.8.2"

terragrunt_version_constraint = ">= 0.34.0, < 0.72"

retryable_errors = [
    "(?s).*Failed to load state.*tcp.*timeout.*",
    "(?s).*Failed to load backend.*TLS handshake timeout.*",
    "(?s).*Client\\.Timeout exceeded while awaiting headers.*",
]