terraform {
  source = "tfr:///terraform-aws-modules/ec2-instance/aws?version=5.7.1"
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

  instance_type = "t3a.small"
  ami           = "ami-0030e4319cbf4dbf2" # Ubuntu 22.04

  vpc_security_group_ids = [dependency.security_group.outputs.security_group_id]
  subnet_id              = dependency.vpc.outputs.public_subnets[0]

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    curl -fsSL https://get.docker.com/ | sh
    apt-get install -y docker-compose
    mkdir -p /opt/pritunl
    cd /opt/pritunl
    cat > docker-compose.yaml << 'EOL'
    version: '3'
    services:
        mongo:
            image: mongo:latest
            container_name: pritunldb
            hostname: pritunldb
            network_mode: bridge
            restart: always
            volumes:
                - ./db:/data/db
        pritunl:
            image: goofball222/pritunl:latest
            container_name: pritunl
            hostname: pritunl
            network_mode: bridge
            privileged: true
            restart: always
            sysctls:
                - net.ipv6.conf.all.disable_ipv6=0
            links:
                - mongo
            volumes:
                - /etc/localtime:/etc/localtime:ro
            ports:
                - 443:443
                - 1194:1194/udp
                - 80:80
            environment:
                - TZ=America/Sao_Paulo
    EOL
    docker compose up -d
  EOF

  # Configurações de IAM role para SSM
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for VPN EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }
  
  # Desabilitar funcionalidades problemáticas
  cpu_core_count = null
  cpu_threads_per_core = null

  root_block_device = [
    {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  ]

  tags = {
    Name = "my-proj-devops-vpn-test"
  }
}
