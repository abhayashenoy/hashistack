variable "aws_access_key"        {}
variable "aws_secret_key"        {}
variable "config_dir"            {}
variable "bin_dir"               {}
variable "worker_ami"            {}
variable "worker_instance_type"  {}
variable "manager_ami"           {}
variable "manager_instance_type" {}
variable "key_name"              {}
variable "aws_region"            {}
variable "bastion_ami"           {}
variable "bastion_instance_type" {}
variable "worker_count" {
  default = 1
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

module "vpc" {
  source = "./vpc"
}

variable "manager_ips" {
  type = "map"
  default = {
    "0" = "10.0.2.10"
    "1" = "10.0.2.20"
    "2" = "10.0.2.30"
  }
}

resource "aws_instance" "managers" {
  ami                         = "${var.manager_ami}"
  instance_type               = "${var.manager_instance_type}"
  vpc_security_group_ids      = ["${module.vpc.cluster_security_group_id}"]
  subnet_id                   = "${module.vpc.subnet_secondary_id}"
  key_name                    = "${var.key_name}"
  private_ip                  = "${lookup(var.manager_ips, count.index)}"
  count                       = 3

  provisioner "remote-exec" {
    connection = {
      user         = "ubuntu"
      private_key  = "${file("${var.key_name}.pem")}"
      bastion_host = "${aws_instance.bastion.public_ip}"
    }
    inline = [
      "sudo sed -i -e 's/%%node-index%%/${count.index}/' -e 's/%%join-master-1%%/${lookup(var.manager_ips, (count.index + 1) % 3)}/' -e 's/%%join-master-2%%/${lookup(var.manager_ips, (count.index + 2) % 3)}/' ${var.config_dir}/consul.json",
      "sudo sed -i -e 's/%%node-ip%%/${lookup(var.manager_ips, count.index)}/' ${var.config_dir}/nomad/base.hcl",
      "sudo sed -i -e 's/%%node-ip%%/${lookup(var.manager_ips, count.index)}/' -e 's/%%node-index%%/${count.index}/' -e 's/%%manager-0-ip%%/${lookup(var.manager_ips, 0)}/' -e 's/%%manager-1-ip%%/${lookup(var.manager_ips, 1)}/' -e 's/%%manager-2-ip%%/${lookup(var.manager_ips, 2)}/'  /etc/default/etcd",
      "sudo systemctl restart consul",
      "sudo systemctl restart nomad",
      "sudo systemctl restart etcd"
    ]
  }
}

resource "null_resource" "manager_setup" {
  triggers {
    manager_ids = "${join(",", aws_instance.managers.*.id)}"
  }

  connection = {
    user         = "ubuntu"
    private_key  = "${file("${var.key_name}.pem")}"
    bastion_host = "${aws_instance.bastion.public_ip}"
    host         = "${aws_instance.managers.0.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ${var.bin_dir}/etcdctl set /coreos.com/network/config '{ \"Network\": \"10.100.0.0/16\" }'"
    ]
  }
}

variable "worker_ips" {
  type = "map"
  default = {
    "0" = "10.0.2.100"
    "1" = "10.0.2.101"
    "2" = "10.0.2.102"
  }
}

resource "aws_instance" "workers" {
  ami                         = "${var.worker_ami}"
  instance_type               = "${var.worker_instance_type}"
  vpc_security_group_ids      = ["${module.vpc.cluster_security_group_id}"]
  subnet_id                   = "${module.vpc.subnet_secondary_id}"
  key_name                    = "${var.key_name}"
  private_ip                  = "${lookup(var.worker_ips, count.index)}"
  count                       = "${var.worker_count}"

  provisioner "remote-exec" {
    connection = {
      user         = "ubuntu"
      private_key  = "${file("${var.key_name}.pem")}"
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
  vpc_security_group_ids      = ["${module.vpc.bastion_security_group_id}"]
  subnet_id                   = "${module.vpc.subnet_primary_id}"
  key_name                    = "${var.key_name}"
  private_ip                  = "10.0.1.254"
  associate_public_ip_address = true
}

output "ips" {
  value = "export MANAGER_0_IP=${aws_instance.managers.0.private_ip} MANAGER_1_IP=${aws_instance.managers.1.private_ip} MANAGER_2_IP=${aws_instance.managers.2.private_ip} WORKER_0_IP=${aws_instance.workers.0.private_ip} BASTION_IP=${aws_instance.bastion.0.public_ip}"
}

resource "aws_alb" "cluster_alb" {
  internal        = false
  security_groups = ["${module.vpc.cluster_security_group_id}"]
  subnets         = ["${module.vpc.subnet_primary_id}", "${module.vpc.subnet_secondary_id}"]
}

resource "aws_alb_target_group" "cluster_target_group" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${module.vpc.vpc_id}"
}

resource "aws_alb_listener" "cluster_listener" {
  load_balancer_arn = "${aws_alb.cluster_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.cluster_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "cluster_listener_rule" {
  listener_arn = "${aws_alb_listener.cluster_listener.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.cluster_target_group.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}

resource "aws_alb_target_group_attachment" "cluster_target_group_attachment" {
  target_group_arn = "${aws_alb_target_group.cluster_target_group.arn}"
  target_id        = "${element(aws_instance.workers.*.id, count.index)}"
  port             = 9999
  count            = "${var.worker_count}"
}

output "alb" {
  value = "export ALB=${aws_alb.cluster_alb.dns_name}"
}
