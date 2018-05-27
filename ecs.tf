#######
# ECS #
#######

resource "aws_ecs_cluster" "simple" {
  name = "simple"
}

data "aws_ami" "amazon_ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_instance" "ecsNode" {
  tags {
    Name = "simple-ecs-node"
  }

  ami                    = "${data.aws_ami.amazon_ecs.image_id}"
  instance_type          = "${var.ecs_instance_type}"
  iam_instance_profile   = "${aws_iam_instance_profile.ecsNode.name}"
  ebs_optimized          = false
  subnet_id              = "${aws_subnet.privateA.id}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ecsNode.id}"]
  monitoring             = true

  user_data = <<USERDATA
#!/bin/bash
sed -i \"s/HOSTNAME=.*/HOSTNAME=simple-ecs-node-$$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)$$(curl http://169.254.169.254/latest/meta-data/ami-launch-index)/\" /etc/sysconfig/network
hostname simple-ecs-node-$$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)$$(curl http://169.254.169.254/latest/meta-data/ami-launch-index)
sed -i \"s/ECS_CLUSTER.*/ECS_CLUSTER=${aws_ecs_cluster.simple.name}/\" /etc/ecs/ecs.config
USERDATA
}

resource "aws_eip" "simple" {
  instance = "${aws_instance.simple.id}"
  vpc      = true

  tags {
    Name     = "simple-ecs-node"
    services = "ecs"
  }
}

resource "aws_iam_instance_profile" "ecsNode" {
  name = "simple-ecs-node"
  role = "${aws_iam_role.ecsNode.name}"
}

resource "aws_iam_role" "ecsNode" {
  name        = "simple-ecs-node"
  description = "Allows ECS Node EC2 instances to call AWS services on your behalf."

  assume_role_policy = "${data.aws_iam_policy_document.ecsNodeAssume.json}"
}

data "aws_iam_policy_document" "ecsNodeAssume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecsNode" {
  name = "simple-ebay-categories"
  role = "${aws_iam_role.ecsNode.name}"

  policy = "${data.aws_iam_policy_document.ecsNode.json}"
}

data "aws_iam_policy_document" "ecsNode" {}

resource "aws_iam_role_policy_attachment" "ecsNodeService" {
  role       = "${aws_iam_role.ecsNode.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_security_group" "ecsNode" {
  name = "simple-ecs-node"

  tags {
    Name = "simple-ecs-node"
  }

  description = "Group to control access for simple ECS nodes"
  vpc_id      = "${aws_vpc.simple.id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "eventsTarget" {
  name        = "simple-eventsTarget"
  path        = "/service-role/"
  description = "Allows AWS Events to trigger targets."

  assume_role_policy = "${data.aws_iam_policy_document.eventsTarget.json}"
}

data "aws_iam_policy_document" "eventsTarget" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "eventsTargetRunECSTask" {
  name = "simple-AWSEventsRunECSTask"
  role = "${aws_iam_role.eventsTarget.name}"

  policy = "${data.aws_iam_policy_document.eventsTargetRunECSTask.json}"
}

data "aws_iam_policy_document" "eventsTargetRunECSTask" {
  statement {
    actions   = ["ecs:RunTask"]
    resources = ["arn:aws:ecs:*:${var.account_id}:task-definition/*"]

    condition {
      test     = "ArnLike"
      variable = "ecs:cluster"
      values   = ["${aws_ecs_cluster.simple.arn}"]
    }
  }
}
