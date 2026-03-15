dependency "vpc" {
  config_path = find_in_parent_folders("vpc")
  
  mock_outputs = {
    vpc_id                       = "vpc-12345678"
    vpc_cidr_block               = "10.0.0.0/16"
    private_subnets              = ["subnet-11111111", "subnet-22222222"]
    public_subnets               = ["subnet-33333333", "subnet-44444444"]
    database_subnets             = ["subnet-55555555", "subnet-66666666"]
    database_subnet_group_name   = "mock-db-subnet-group"
  }
}
