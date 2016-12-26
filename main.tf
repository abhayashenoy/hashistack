variable "aws_access_key"        {}
variable "aws_secret_key"        {}
variable "aws_region"            {}

variable "config_dir"            {}
variable "bin_dir"               {}

variable "keyfile"               {}

variable "worker_ami"            {}
variable "worker_instance_type"  {}
variable "worker_count"          {}

variable "manager_ami"           {}
variable "manager_instance_type" {}
variable "manager_count"         {}

variable "bastion_ami"           {}
variable "bastion_instance_type" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_key_pair" "keypair" {
  key_name   = "terraform-key"
  public_key = "${file("${var.keyfile}.pub")}"
}
