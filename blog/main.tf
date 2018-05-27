provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "usEast1"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-simple"
    key            = "simple-blog.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform_locks"
  }
}

data "aws_region" "current" {}

### DNS ###

# Uncomment this if you're using Route 53 for DNS.
# Also uncomment the records in the application tf files
# resource "aws_route53_zone" "simple" {
#   name          = "${var.domain}."
#   comment       = "simple-domain"
#   force_destroy = true
# }

# If you're using sub-domains for separate applications then
# use this datasource instead and change the records in the
# application tf files to reference ${data.aws_route53_zone.simple.zone_id}
# data "aws_route53_zone" "simple" {
#   name         = "${var.domain}."
# }

## ECS Cluster ##

data "aws_ecs_cluster" "sinple" {
  cluster_name = "simple"
}

### variables ###

# Create a terraform.tfvars file and set `account_id = "YOUR_ACCOUNT_ID"`,
# `ecs_node_eip_id = "EIP_ID"`, and `domain = "YOUR_DOMAIN"` in it
# Populate account_id with your AWS account ID, ecs_node_eip_id with the id of
# the Elastic IP attached to the ECS node ec2 instance if you're using Route 53
# for DNS, and domain with your root domain (no sub-domain)

variable "account_id" {}

variable "ecs_node_eip_id" {
  default = ""
}

variable "domain" {
  default = "simple-domain.co.uk"
}

# This can be left as live unless you have a dev version hosted
variable "environment" {
  default = "live"
}
