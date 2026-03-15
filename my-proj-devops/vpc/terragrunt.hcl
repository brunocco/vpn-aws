terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.1.2"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  name   = basename(get_terragrunt_dir())
  region = include.root.locals.region
}

inputs = {
  name = "my-proj-devops-${local.name}-test"
  
  cidr = "10.0.0.0/16"
  azs  = ["${local.region}a", "${local.region}b"]

  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  database_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  public_subnets   = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  create_database_subnet_group = true
  
  tags = {
    Name = "my-proj-devops-vpc-test"
  }
}
