provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket         = "REPLACE_THIS_WITH_YOUR_BUCKET_NAME"
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

# Uncomment this if you're using Route 53 for DNS and multiple applications are on sub-domains in that root domain.
# resource "aws_route53_zone" "simple" {
#   name          = "${var.root_domain}."
#   comment       = "simple-domain"
#   force_destroy = true
# }

