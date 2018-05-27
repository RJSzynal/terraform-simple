provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-simple"
    key            = "simple-account.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform_locks"
  }
}

data "aws_region" "current" {}

# General #

# Create a terraform.tfvars file and set `account_id = "YOUR_ACCOUNT_ID"`
# and `private_key_name = "YOUR_PRIVATE_KEY_NAME"` in it
variable "account_id" {}

variable "private_key_name" {}

# ECS Nodes #
variable "ecs_instance_type" {
  default = "t2.micro"
}

variable "environment" {
  default = "live"
}
