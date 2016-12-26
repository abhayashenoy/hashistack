resource "aws_vpc" "vpc" {
  cidr_block         = "10.0.0.0/16"
  enable_dns_support = true
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
}

resource "aws_security_group" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  # HTTP for ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # all connections from bastion vpc
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.public.id}"]
  }

  # All internal->internal VPC connections allowed
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # All internat->external VPC connections allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH -- maybe can go away later
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All internat->external VPC connections allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outgoing connections from VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# Overriding the VPC main routing table
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_main_route_table_association" "public" {
  vpc_id         = "${aws_vpc.vpc.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.private.id}"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "private" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.id}"
  depends_on    = ["aws_internet_gateway.gw"]
}
