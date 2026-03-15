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
  description = "Security group for App EC2 instance"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
      description = "SSH from VPC"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
      description = "HTTP from VPC"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
      description = "HTTPS from VPC"
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
    Name = "my-proj-devops-app-sg-test"
  }
}
