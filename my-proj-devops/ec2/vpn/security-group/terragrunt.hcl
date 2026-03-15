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
  description = "Security group for VPN EC2 instance"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS access"
    },
    {
      from_port   = 1194
      to_port     = 1194
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
      description = "OpenVPN UDP"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP access"
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
    Name = "my-proj-devops-vpn-sg-test"
  }
}
