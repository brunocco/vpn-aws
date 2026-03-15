terraform {
  source = "tfr:///terraform-aws-modules/rds/aws?version=6.3.0"
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
  name = basename(get_terragrunt_dir())
}

inputs = {
  identifier = "my-proj-devops-${local.name}-test"

  engine               = "postgres"
  engine_version       = "15.8"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "vpntest"
  username = "postgres"
  port     = 5432

  # IMPORTANTE: Altere esta senha em produção!
  password = "ChangeMeInProduction123!"

  multi_az               = false
  db_subnet_group_name   = dependency.vpc.outputs.database_subnet_group_name
  vpc_security_group_ids = [dependency.security_group.outputs.security_group_id]

  publicly_accessible = false

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = false
  create_monitoring_role                = false
  create_db_parameter_group             = true
  create_db_option_group                = false

  tags = {
    Name = "my-proj-devops-rds-test"
  }
}
