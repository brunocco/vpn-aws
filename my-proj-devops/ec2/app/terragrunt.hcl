terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=2.15.0"
}

include "root" { 
  path   = find_in_parent_folders("root.hcl") 
  expose = true
}

include "vpc" {
  path   = find_in_parent_folders("_envcommon/vpc.hcl")
  expose = true
}

dependency "security_group" {
  config_path = "./security-group"
  mock_outputs = {
    security_group_id = "sg-mock"
  }
}

locals {
  name       = basename(get_terragrunt_dir())
  group_name = basename(dirname(get_terragrunt_dir()))
}

inputs = {
  name = "my-proj-devops-${local.name}-test"

  instance_type = "t3a.micro"
  ami           = "ami-0854ab933beb175ce" # Amazon Linux 2023 (mais recente)
  key_name      = "vpn-test-key"  # Chave SSH criada

  vpc_security_group_ids = [dependency.security_group.outputs.security_group_id]
  subnet_id              = dependency.vpc.outputs.private_subnets[0]

  associate_public_ip_address = false
  
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>VPN Test App Server</h1>" > /usr/share/nginx/html/index.html
  EOF

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for App EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  root_block_device = [
    {
      volume_size = 30
      volume_type = "gp3"
      encrypted   = true
    }
  ]

  tags = {
    Name = "my-proj-devops-app-test"
  }
}
