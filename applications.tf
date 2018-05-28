################
# Applications #
################

### Blog ###

# Many of the entries here can be omitted as they are using defaults.
# I provide them only as an example/template.
module "blog" {
  source = "./php-mysql"

  environment        = "${var.environment}"
  aws_region         = "${data.aws_region.current.name}"
  aws_ecs_cluster    = "${aws_ecs_cluster.salepack.name}"
  aws_eip_public_ip  = "${aws_eip.simple.public_ip}"
  root_domain        = "simple-domain.co.uk"
  full_domain        = "blog.simple-domain.co.uk"
  name               = "blog"
  app_src_location   = "/home/ec2-user/blog"
  cpu                = "24"
  memory_reservation = "64"
  memory_hard_limit  = "256"
  php_version        = "7.2"
  mysql_version      = "5.7"
}
