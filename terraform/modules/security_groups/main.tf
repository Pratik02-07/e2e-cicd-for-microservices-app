resource "aws_security_group" "ec2_sg" {
  name        = "${var.env_name}-ec2-sg"
  description = "Security group for ${var.env_name} EC2 instances"
  vpc_id      = var.vpc_id

  # SSH - restrict in production
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  # HTTP - frontend
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
  }

  # Product service
  ingress {
    description = "Product Service"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
  }

  # Cart service
  ingress {
    description = "Cart Service"
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env_name}-ec2-sg"
  })
}