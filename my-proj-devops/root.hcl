locals {
  region = "us-east-1"
  
  # Carrega configurações do config.hcl
  config = read_terragrunt_config(find_in_parent_folders("config.hcl"))
  aws_profile = local.config.locals.aws_profile
  
  # Carrega variáveis do vars.hcl
  vars = read_terragrunt_config(find_in_parent_folders("vars.hcl"))
  project_name = local.vars.locals.project_name
  environment = local.vars.locals.environment
}

# Configuração do remote state no S3 com lock no DynamoDB
remote_state {
  backend = "s3"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  
  config = {
    profile        = local.aws_profile
    region         = local.region
    bucket         = "${local.project_name}-terraform-state-${local.environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "${local.project_name}-terraform-lock-${local.environment}"
    
    # Configurações para criação automática do bucket e tabela
    skip_bucket_versioning = false
    skip_bucket_ssencryption = false
    skip_bucket_public_access_blocking = false
    skip_requesting_account_id = false
    skip_credentials_validation = false
    skip_metadata_api_check = false
    
    s3_bucket_tags = {
      Name        = "${local.project_name}-terraform-state"
      Environment = local.environment
      ManagedBy   = "Terragrunt"
    }
    
    dynamodb_table_tags = {
      Name        = "${local.project_name}-terraform-lock"
      Environment = local.environment
      ManagedBy   = "Terragrunt"
    }
  }
}

# Gera o provider AWS automaticamente
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region  = "${local.region}"
  profile = "${local.aws_profile}"
  version = "~> 5.0"
  
  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Environment = "${local.environment}"
      ManagedBy   = "Terragrunt"
    }
  }
}
EOF
}
