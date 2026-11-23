data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "this" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_groups
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name

  user_data = base64encode(file("user-data.sh"))

  tags = merge(var.tags, var.extra_tags)

  # Industry standard: terminate with protection off for dev, on for prod
  disable_api_termination = var.env_name == "prod"

  lifecycle {
    create_before_destroy = true
  }
}