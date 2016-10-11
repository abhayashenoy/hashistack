variable "security_group" {}
variable "subnet_main" {}
variable "subnet_secondary" {}

resource "aws_db_subnet_group" "subnet_group" {
  name = "hashistack_db_subnet"
  subnet_ids = ["${var.subnet_main}", "${var.subnet_secondary}"]
}

resource "aws_db_instance" "db" {
  allocated_storage      = 5
  engine                 = "postgres"
  instance_class         = "db.t1.micro"
  name                   = "atc"
  username               = "consul"
  password               = "consul"
  vpc_security_group_ids = ["${var.security_group}"]
  db_subnet_group_name   = "${aws_db_subnet_group.subnet_group.name}"
  lifecycle = {
    prevent_destroy      = false
  }
}

output "db_url" {
  value = "${aws_db_instance.db.address}"
}

output "db_user" {
  value = "${aws_db_instance.db.username}"
}

output "db_connection_string" {
  value = "postgres://${aws_db_instance.db.username}:${aws_db_instance.db.password}@${aws_db_instance.db.address}/atc?sslmode=disable"
}
