module "microservices_infra" {
  source = "../../"

  env_name            = "dev"
  instance_type       = "t3.micro"
  key_name            = var.key_name
  availability_zones  = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  # ami_id defaults to latest Amazon Linux 2023 from data source
}
