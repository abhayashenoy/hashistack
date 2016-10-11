variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "ip_one"   {
  default = "10.0.1.10"
}
variable "ip_two" {
  default = "10.0.1.20"
}
variable "ip_three" {
  default = "10.0.1.30"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "ap-southeast-1"
}

module "vpc" {
  source = "./vpc"
}

/*
module "db" {
  source = "./db"

  security_group     = "${module.vpc.security_group_id}"
  subnet_main        = "${module.vpc.subnet_primary_id}"
  subnet_secondary   = "${module.vpc.subnet_secondary_id}"
}
*/

module "master" {
  source = "./basevm"

  security_group_id = "${module.vpc.security_group_id}"
  subnet_id         = "${module.vpc.subnet_primary_id}"
  name              = "master"
  ip                = "${var.ip_one}"
  ip_one            = "${var.ip_two}"
  ip_two            = "${var.ip_three}"
}

module "slave-one" {
  source = "./basevm"

  security_group_id  = "${module.vpc.security_group_id}"
  subnet_id          = "${module.vpc.subnet_primary_id}"
  name              = "slave-one"
  ip                = "${var.ip_two}"
  ip_one            = "${var.ip_one}"
  ip_two            = "${var.ip_three}"
}

module "slave-two" {
  source = "./basevm"

  security_group_id  = "${module.vpc.security_group_id}"
  subnet_id          = "${module.vpc.subnet_primary_id}"
  name               = "slave-two"
  ip                 = "${var.ip_three}"
  ip_one             = "${var.ip_one}"
  ip_two             = "${var.ip_two}"
}

module "worker-one" {
  source = "./worker"

  security_group_id  = "${module.vpc.security_group_id}"
  subnet_id          = "${module.vpc.subnet_primary_id}"
  name               = "worker-one"
  ip                 = "10.0.1.110"
  ip_one             = "${var.ip_one}"
  ip_two             = "${var.ip_two}"
  ip_three           = "${var.ip_three}"
}

module "worker-two" {
  source = "./worker"

  security_group_id  = "${module.vpc.security_group_id}"
  subnet_id          = "${module.vpc.subnet_primary_id}"
  name               = "worker-two"
  ip                 = "10.0.1.120"
  ip_one             = "${var.ip_one}"
  ip_two             = "${var.ip_two}"
  ip_three           = "${var.ip_three}"
}

module "worker-three" {
  source = "./worker"

  security_group_id  = "${module.vpc.security_group_id}"
  subnet_id          = "${module.vpc.subnet_primary_id}"
  name               = "worker-three"
  ip                 = "10.0.1.130"
  ip_one             = "${var.ip_one}"
  ip_two             = "${var.ip_two}"
  ip_three           = "${var.ip_three}"
}

output "master_ip" {
  value = "export MASTER_IP=${module.master.public_ip}"
}

output "worker_one_ip" {
  value = "export WORKER_ONE_IP=${module.worker-one.private_ip}"
}


