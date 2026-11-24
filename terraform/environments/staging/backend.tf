terraform {
  backend "s3" {
    bucket         = "pratik-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "pratik-terraform-lock"
    encrypt        = true
  }
}