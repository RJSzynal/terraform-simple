########
# Blog #
########

data "aws_ecs_task_definition" "blog" {
  task_definition = "${var.environment}-blog"

  # Comment this out after initial task definition creation
  depends_on = ["aws_ecs_task_definition.blog"]
}

resource "aws_ecs_task_definition" "blog" {
  family        = "${aws_cloudwatch_log_group.blog.name}"
  task_role_arn = "${aws_iam_role.blog.arn}"

  container_definitions = <<DEF
[
  {
    "name": "blog",
    "image": "nginx:alpine",
    "cpu": 8,
    "memoryReservation": 200,
    "essential": true,
    "links": [
        "blog-mysql:mysql",
        "blog-php:php-fpm"
    ],
    "portMappings": [
      {
        "containerPort": 80
      }
    ],
    "hostname": "${aws_cloudwatch_log_group.blog.name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.blog.name}",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "1-13"
      }
    }
  },
  {
    "name": "blog-mysql",
    "image": "mysql:5.7",
    "cpu": 8,
    "memoryReservation": 200,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 3306,
        "hostPort": 3306
      }
    ],
    "hostname": "${aws_cloudwatch_log_group.blogMysql.name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.blogMysql.name}",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "5-7"
      }
    }
  },
  {
    "name": "blog-php",
    "image": "phpdocker/php-fpm",
    "cpu": 128,
    "memoryReservation": 200,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 9000
      }
    ],
    "hostname": "${aws_cloudwatch_log_group.blogPHP.name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.blogPHP.name}",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "7-2"
      }
    }
  }
]
DEF
}

resource "aws_cloudwatch_log_group" "blog" {
  name              = "${var.environment}-blog"
  retention_in_days = 14

  tags {
    environment = "${var.environment}"
    services    = "blog"
  }
}

resource "aws_cloudwatch_log_group" "blogPHP" {
  name              = "${var.environment}-blog-php"
  retention_in_days = 14

  tags {
    environment = "${var.environment}"
    services    = "blog-php"
  }
}

resource "aws_cloudwatch_log_group" "blogMysql" {
  name              = "${var.environment}-blog-mysql"
  retention_in_days = 14

  tags {
    environment = "${var.environment}"
    services    = "blog-mysql"
  }
}

resource "aws_ecs_service" "blog" {
  name            = "${aws_cloudwatch_log_group.blog.name}"
  cluster         = "${data.aws_ecs_cluster.simple.name}"
  task_definition = "${aws_ecs_task_definition.blog.family}:${max("${aws_ecs_task_definition.blog.revision}", "${data.aws_ecs_task_definition.blog.revision}")}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.blog.name}"
}

## DNS ##

# Uncomment both if using Route 53 for DNS.
# resource "aws_route53_record" "base" {
#   zone_id = "${aws_route53_zone.simple.zone_id}"
#   name    = "${var.domain}"
#   type    = "A"
#   ttl     = "300"
#   records = ["${data.aws_eip.simple.public_ip}"]
# }

# data "aws_eip" "simple" {
#   id = "${var.ecs_node_eip_id}"
# }

## Security ##

resource "aws_iam_role" "blog" {
  name        = "${var.environment}-blog"
  description = "Allows Blog ECS tasks to call AWS services on your behalf."

  assume_role_policy = "${data.aws_iam_policy_document.blogAssume.json}"
}

data "aws_iam_policy_document" "blogAssume" {
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

resource "aws_iam_role_policy" "blog" {
  name = "${var.environment}-blog"
  role = "${aws_iam_role.blog.name}"

  policy = "${data.aws_iam_policy_document.blog.json}"
}

data "aws_iam_policy_document" "blog" {
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

resource "aws_iam_role_policy_attachment" "ecsServiceBlog" {
  role       = "${aws_iam_role.blog.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
