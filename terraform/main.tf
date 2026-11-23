# ------------------------------------------------------------
# Root Terraform module
# Provisions VPC, security groups, IAM role, and EC2 instances
# for one environment (dev / staging / prod)
# ------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  env_name       = var.env_name
  cidr_block     = var.vpc_cidr
  azs            = var.availability_zones
  public_subnets = var.public_subnet_cidrs
  tags           = var.common_tags
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id   = module.vpc.vpc_id
  env_name = var.env_name
  ssh_cidr = var.ssh_cidr
  app_cidr = "0.0.0.0/0" # tighten to your corporate IP in prod
  tags     = var.common_tags
}

module "iam" {
  source = "./modules/iam"

  env_name = var.env_name
  tags     = var.common_tags
}

module "ec2" {
  source = "./modules/ec2"

  env_name             = var.env_name
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnet_ids[0] # single AZ per env for demo
  security_groups      = [module.security_groups.ec2_sg_id]
  iam_instance_profile = module.iam.ec2_instance_profile_name
  instance_type        = var.instance_type
  ami_id               = var.ami_id
  key_name             = var.key_name
  tags                 = var.common_tags

  # Ansible dynamic inventory discovers these tags
  extra_tags = {
    Environment  = var.env_name
    AnsibleGroup = var.env_name == "prod" ? "prod_servers" : var.env_name == "staging" ? "staging_servers" : "dev_servers"
    ManagedBy    = "terraform"
    Project      = "microservices-cicd-capstone"
  }
}
