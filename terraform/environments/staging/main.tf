module "microservices_infra" {
  source = "../../"

  env_name            = "staging"
  instance_type       = "t3.micro"
  key_name            = var.key_name
  availability_zones  = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}
