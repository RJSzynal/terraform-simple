#######
# VPC #
#######

##### Availability Zone A #####

## PUBLIC ##

resource "aws_subnet" "publicA" {
  vpc_id                  = "${aws_vpc.simple.id}"
  availability_zone       = "${data.aws_region.current.name}a"
  cidr_block              = "172.30.0.0/24"
  map_public_ip_on_launch = "true"

  tags {
    Name = "Simple Public A"
  }
}

resource "aws_route_table_association" "publicA" {
  subnet_id      = "${aws_subnet.publicA.id}"
  route_table_id = "${aws_route_table.public.id}"
}

##### Other Infrastructure #####

resource "aws_vpc" "simple" {
  cidr_block           = "172.30.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "Simple"
  }
}

resource "aws_vpc_dhcp_options_association" "simple" {
  vpc_id          = "${aws_vpc.simple.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.simple.id}"
}

resource "aws_vpc_dhcp_options" "simple" {
  domain_name         = "${data.aws_region.current.name}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    Name = "Simple"
  }
}

resource "aws_internet_gateway" "simple" {
  vpc_id = "${aws_vpc.simple.id}"

  tags {
    Name = "Simple Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.simple.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.simple.id}"
  }

  tags {
    Name = "Simple Public"
  }
}
