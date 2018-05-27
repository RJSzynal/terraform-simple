#########
# Proxy #
#########

data "aws_ecs_task_definition" "proxy" {
  task_definition = "proxy"

  # Comment this out after initial task definition creation
  depends_on = ["aws_ecs_task_definition.proxy"]
}

resource "aws_ecs_task_definition" "proxy" {
  family        = "${aws_cloudwatch_log_group.proxy.name}"
  task_role_arn = "${aws_iam_role.proxy.arn}"

  container_definitions = <<DEF
[
  {
    "name": "proxy",
    "image": "jwilder/nginx-proxy:alpine-0.7.0",
    "cpu": 8,
    "memoryReservation": 10,
    "essential": true,
    "links": [
        "proxy-mysql:mysql",
        "proxy-php:php-fpm"
    ],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      },
      {
        "containerPort": 443,
        "hostPort": 443
      }
    ],
    "hostname": "${aws_cloudwatch_log_group.proxy.name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.proxy.name}",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "1-13"
      }
    }
  },
  {
    "name": "ssl-termination",
    "image": "jrcs/letsencrypt-nginx-proxy-companion",
    "cpu": 8,
    "memoryReservation": 10,
    "essential": true,
    "hostname": "${aws_cloudwatch_log_group.sslTermination.name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.sslTermination.name}",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "5-7"
      }
    }
  }
]
DEF
}

resource "aws_cloudwatch_log_group" "proxy" {
  name              = "proxy"
  retention_in_days = 14

  tags {
    contract    = "${var.contract}"
    environment = "${var.environment}"
    services    = "proxy"
  }
}

resource "aws_cloudwatch_log_group" "sslTermination" {
  name              = "proxy-ssl-termination"
  retention_in_days = 14

  tags {
    contract    = "${var.contract}"
    environment = "${var.environment}"
    services    = "proxy-ssl-termination"
  }
}

resource "aws_ecs_service" "proxy" {
  name            = "${aws_cloudwatch_log_group.proxy.name}"
  cluster         = "${aws_ecs_cluster.simple.name}"
  task_definition = "${aws_ecs_task_definition.proxy.family}:${max("${aws_ecs_task_definition.proxy.revision}", "${data.aws_ecs_task_definition.proxy.revision}")}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.proxy.name}"
}

## Security ##

resource "aws_iam_role" "proxy" {
  name        = "proxy"
  description = "Allows Proxy ECS tasks to call AWS services on your behalf."

  assume_role_policy = "${data.aws_iam_policy_document.proxyAssume.json}"
}

data "aws_iam_policy_document" "proxyAssume" {
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

resource "aws_iam_role_policy" "proxy" {
  name = "proxy"
  role = "${aws_iam_role.proxy.name}"

  policy = "${data.aws_iam_policy_document.proxy.json}"
}

data "aws_iam_policy_document" "proxy" {
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

resource "aws_iam_role_policy_attachment" "ecsServiceProxy" {
  role       = "${aws_iam_role.proxy.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
