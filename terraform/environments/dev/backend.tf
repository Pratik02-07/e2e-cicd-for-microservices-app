terraform {
  backend "s3" {
    bucket         = "pratik-terraform-state"   # create this bucket first
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pratik-terraform-lock"    # create this table first
    encrypt        = true
  }
}