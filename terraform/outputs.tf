output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "ec2_public_ip" {
  value       = module.ec2.public_ip
  description = "Public IP of the EC2 instance"
}

output "ec2_private_ip" {
  value       = module.ec2.private_ip
  description = "Private IP of the EC2 instance"
}

output "ec2_instance_id" {
  value       = module.ec2.instance_id
  description = "EC2 instance ID"
}

output "ec2_public_dns" {
  value       = module.ec2.public_dns
  description = "Public DNS name"
}

output "security_group_id" {
  value       = module.security_groups.ec2_sg_id
  description = "EC2 security group ID"
}