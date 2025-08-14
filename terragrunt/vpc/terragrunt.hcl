terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws//?version=5.8.1"
}

locals {
  vpc_cidr   = "10.0.0.0/16"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {
  name = "${include.root.locals.project}-vpc"

  cidr                = local.vpc_cidr
  azs                 = ["${include.root.locals.aws_region}a", "${include.root.locals.aws_region}b", "${include.root.locals.aws_region}c"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}
