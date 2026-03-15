terraform {
  source = "tfr:///terraform-aws-modules/security-group/aws?version=5.1.0"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "vpc" {
  path   = find_in_parent_folders("_envcommon/vpc.hcl")
  expose = true
}

locals {
  name = basename(dirname(get_terragrunt_dir()))
}

inputs = {
  name        = "my-proj-devops-${local.name}-sg-test"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
      description = "PostgreSQL from VPC"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

  tags = {
    Name = "my-proj-devops-rds-sg-test"
  }
}
