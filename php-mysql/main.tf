### Inputs ###

variable "environment" {
  type        = "string"
  default     = "live"
  description = "(optional) The environment of the endpoint, e.g. qa, st, live (default: live)"
}

variable "aws_region" {
  type        = "string"
  default     = "us-east-1"
  description = "(optional) The region the endpoint is in, e.g. eu-west-1 (default: us-east-1)"
}

variable "aws_ecs_cluster" {
  type        = "string"
  description = "The name of the cluster the endpoint is hosted in"
}

variable "aws_eip_public_ip" {
  type        = "string"
  default     = ""
  description = "(optional) The public IP of the Elastic IP attached to the ECS node ec2 instance. Required if you're using Route 53 for DNS"
}

variable "root_domain" {
  type        = "string"
  default     = ""
  description = "(optional) The root domain name for this application, e.g. simple-domain.co.uk. Required if you're using Route 53 for DNS"
}

variable "full_domain" {
  type        = "string"
  description = "The full domain name for this application, e.g. blog.simple-domain.co.uk"
}

variable "name" {
  type        = "string"
  description = "The name of the application, e.g. blog"
}

variable "app_src_location" {
  type        = "string"
  description = "The location of the application source on the host, e.g. /home/ec2-user/blog"
}

variable "cpu" {
  type        = "string"
  default     = 32
  description = "(optional) The cpu requirement of the container (default: 32)"
}

variable "memory_reservation" {
  type        = "string"
  default     = 64
  description = "(optional) The expected memory usage of the container (default: 64)"
}

variable "memory_hard_limit" {
  type        = "string"
  default     = 256
  description = "(optional) The memory limit at which the container will be stopped (default: 256)"
}

variable "php_version" {
  type        = "string"
  default     = "7.2"
  description = "(optional) The PHP version to use (default: 7.2)"
}

variable "mysql_version" {
  type        = "string"
  default     = "5.7"
  description = "(optional) The MySQL version to use (default: 5.7)"
}

### Resources ###

resource "aws_ecs_task_definition" "application" {
  family        = "${aws_cloudwatch_log_group.webserver.name}"
  task_role_arn = "${aws_iam_role.application.arn}"

  volume = {
    name      = "app_src"
    host_path = "${var.app_src_location}"
  }

  container_definitions = <<DEF
[
  {
    "name": "${var.name}-webserver",
    "image": "php:${var.php_version}-apache",
    "cpu": ${var.cpu},
    "memory": ${var.memory_hard_limit},
    "memoryReservation": ${var.memory_reservation},
    "essential": true,
    "environment": [
      "VIRTUAL_HOST": "${var.full_domain}",
      "VIRTUAL_PORT": "80",
      "LETSENCRYPT_HOST": "${var.full_domain}",
      "LETSENCRYPT_EMAIL": "${var.hostmaster_email}",
      "HTTPS_METHOD": "redirect,
    ],
    "mountPoints": [
      {
        "sourceVolume": "app_src",
        "containerPath": "/var/www/html",
        "readonly": false
      }
    ],
    "links": [
      "${var.name}-mysql:mysql"
    ],
    "portMappings": [
      {
        "containerPort": 80
      }
    ],
    "hostname": "${aws_cloudwatch_log_group.webserver.name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.webserver.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${replace("${var.php_version}", ".", "-")}"
      }
    }
  },
  {
    "name": "${var.name}-mysql",
    "image": "mysql:${var.mysql_version}",
    "cpu": ${var.cpu},
    "memory": ${var.memory_hard_limit},
    "memoryReservation": ${var.memory_reservation},
    "essential": true,
    "portMappings": [
      {
        "containerPort": 3306
      }
    ],
    "hostname": "${aws_cloudwatch_log_group.mysql.name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.mysql.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${replace("${var.mysql_version}", ".", "-")}"
      }
    }
  }
]
DEF
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "${var.environment}-${var.name}-webserver"
  retention_in_days = 14

  tags {
    environment = "${var.environment}"
    services    = "application"
  }
}

resource "aws_cloudwatch_log_group" "mysql" {
  name              = "${var.environment}-${var.name}-mysql"
  retention_in_days = 14

  tags {
    environment = "${var.environment}"
    services    = "${var.name}-mysql"
  }
}

resource "aws_ecs_service" "application" {
  name            = "${aws_cloudwatch_log_group.webserver.name}"
  cluster         = "${var.aws_ecs_cluster}"
  task_definition = "${aws_ecs_task_definition.application.family}:${aws_ecs_task_definition.application.revision}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.application.name}"
}

## Security ##

resource "aws_iam_role" "application" {
  name        = "${var.environment}-${var.name}"
  description = "Allows application ECS tasks to call AWS services on your behalf."

  assume_role_policy = "${data.aws_iam_policy_document.applicationAssume.json}"
}

data "aws_iam_policy_document" "applicationAssume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "application" {
  name = "${var.environment}-${var.name}"
  role = "${aws_iam_role.application.name}"

  policy = "${data.aws_iam_policy_document.application.json}"
}

data "aws_iam_policy_document" "application" {
  # Allows logging
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "ecsServiceapplication" {
  role       = "${aws_iam_role.application.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

## DNS


# Uncomment this if you're using Route 53 for DNS and this is the only application using that root domain.
# resource "aws_route53_zone" "simple" {
#   name          = "${var.root_domain}."
#   comment       = "simple-domain"
#   force_destroy = true
# }


# Uncomment this if you're using Route 53 for DNS and you're using sub-domains for separate applications.
# Also, change the zone id in the 'aws_route53_record' resource below to reference
# ${data.aws_route53_zone.simple.zone_id} and ensure the full_domain variable is set to match the
# 'aws_route53_zone' resource in the main.tf in the root project
# data "aws_route53_zone" "simple" {
#   name         = "${var.root_domain}."
# }


# Uncomment this if you're using Route 53 for DNS.
# resource "aws_route53_record" "base" {
#   zone_id = "${aws_route53.simple.zone_id}"
#   name    = "${var.full_domain}"
#   type    = "A"
#   ttl     = "300"
#   records = ["${var.aws_eip_public_ip}"]
# }

