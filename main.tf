variable "aws_access_key"        {}
variable "aws_secret_key"        {}
variable "config_dir"            {}
variable "worker_ami"            {}
variable "worker_instance_type"  {}
variable "manager_ami"           {}
variable "manager_instance_type" {}
variable "key_name"              {}
variable "aws_region"            {}
variable "bastion_ami"           {}
variable "bastion_instance_type" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

module "vpc" {
  source = "./vpc"
}

variable "manager_ips" {
  default = {
    "0" = "10.0.1.10"
    "1" = "10.0.1.20"
    "2" = "10.0.1.30"
  }
}

resource "aws_instance" "managers" {
  ami                         = "${var.manager_ami}"
  instance_type               = "${var.manager_instance_type}"
  vpc_security_group_ids      = ["${module.vpc.security_group_id}"]
  subnet_id                   = "${module.vpc.subnet_primary_id}"
  key_name                    = "${var.key_name}"
  private_ip                  = "${lookup(var.manager_ips, count.index)}"
  count                       = 3

  provisioner "remote-exec" {
    connection = {
      user = "ubuntu"
      private_key = "${file("${var.key_name}.pem")}"
      bastion_host = "${aws_instance.bastion.public_ip}"
    }
    inline = [
      "sudo sed -i -e 's/%%node-name%%/manager-${count.index}/' -e 's/%%join-master-1%%/${lookup(var.manager_ips, (count.index + 1) % 3)}/' -e 's/%%join-master-2%%/${lookup(var.manager_ips, (count.index + 2) % 3)}/' ${var.config_dir}/consul.json",
      "sudo sed -i -e 's/%%IP%%/${lookup(var.manager_ips, count.index)}/' ${var.config_dir}/nomad/base.hcl",
      "sudo systemctl restart consul",
      "sudo systemctl restart nomad"
    ]
  }
}

variable "worker_ips" {
  default = {
    "0" = "10.0.1.100"
    "1" = "10.0.1.101"
    "2" = "10.0.1.102"
  }
}

resource "aws_instance" "workers" {
  ami                         = "${var.worker_ami}"
  instance_type               = "${var.worker_instance_type}"
  vpc_security_group_ids      = ["${module.vpc.security_group_id}"]
  subnet_id                   = "${module.vpc.subnet_primary_id}"
  key_name                    = "${var.key_name}"
  private_ip                  = "${lookup(var.worker_ips, count.index)}"
  count                       = 1

  provisioner "remote-exec" {
    connection = {
      user = "ubuntu"
      private_key = "${file("${var.key_name}.pem")}"
      bastion_host = "${aws_instance.bastion.public_ip}"
    }
    inline = [
      "sudo sed -i -e 's/%%node-name%%/worker-${count.index}/' -e 's/%%join-master-1%%/${lookup(var.manager_ips, 0)}/' -e 's/%%join-master-2%%/${lookup(var.manager_ips, 1)}/' ${var.config_dir}/consul.json",
      "sudo systemctl restart consul",
      "sudo systemctl restart nomad"
    ]
  }
}

resource "aws_instance" "bastion" {
  ami                         = "${var.bastion_ami}"
  instance_type               = "${var.bastion_instance_type}"
  vpc_security_group_ids      = ["${module.vpc.security_group_id}"]
  subnet_id                   = "${module.vpc.subnet_primary_id}"
  key_name                    = "${var.key_name}"
  private_ip                  = "10.0.1.254"
  associate_public_ip_address = true
}

output "ips" {
  value = "export MANAGER_0_IP=${aws_instance.managers.0.private_ip} MANAGER_1_IP=${aws_instance.managers.1.private_ip} MANAGER_2_IP=${aws_instance.managers.2.private_ip} WORKER_0_IP=${aws_instance.workers.0.private_ip} BASTION_IP=${aws_instance.bastion.0.public_ip}"
}
