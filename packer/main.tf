variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "ami"            {}
variable "region"         {}
variable "az"             {}
variable "keyfile"        {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
}

resource "aws_subnet" "primary" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.az}"
}

resource "aws_security_group" "sg" {
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH -- maybe can go away later
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All internal->internal VPC connections allowed
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  # All internat->external VPC connections allowed
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outgoing connections from VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# Overriding the VPC main routing table
resource "aws_route_table" "routes" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_main_route_table_association" "main_routes" {
  vpc_id = "${aws_vpc.vpc.id}"
  route_table_id = "${aws_route_table.routes.id}"
}

resource "aws_key_pair" "keypair" {
  key_name = "terraform-key"
  public_key = "${file("${var.keyfile}")}"
}

resource "aws_instance" "instance" {
  ami                         = "${var.ami}"
  instance_type               = "t2.nano"
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  subnet_id                   = "${aws_subnet.primary.id}"
  private_ip                  = "10.0.1.10"
  key_name                    = "${aws_key_pair.keypair.key_name}"
  associate_public_ip_address = true
}

output "public_ip" {
  value = "${aws_instance.instance.public_ip}"
}
