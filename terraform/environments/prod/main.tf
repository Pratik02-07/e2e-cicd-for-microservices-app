module "microservices_infra" {
  source = "../../"

  env_name            = "prod"
  instance_type       = "t3.small"
  key_name            = var.key_name
  availability_zones  = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
}