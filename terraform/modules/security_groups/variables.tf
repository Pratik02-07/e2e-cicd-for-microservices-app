variable "vpc_id" { type = string }
variable "env_name" { type = string }
variable "ssh_cidr" { type = string }
variable "app_cidr" { type = string }
variable "tags" { type = map(string) }