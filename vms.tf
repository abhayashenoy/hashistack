resource "aws_instance" "managers" {
  ami                         = "${var.manager_ami}"
  instance_type               = "${var.manager_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.private.id}"]
  subnet_id                   = "${aws_subnet.private.id}"
  key_name                    = "${aws_key_pair.keypair.key_name}"
  count                       = "${var.manager_count}"
}

resource "aws_instance" "workers" {
  ami                         = "${var.worker_ami}"
  instance_type               = "${var.worker_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.private.id}"]
  subnet_id                   = "${aws_subnet.private.id}"
  key_name                    = "${aws_key_pair.keypair.key_name}"
  count                       = "${var.worker_count}"
}

resource "aws_instance" "bastion" {
  ami                         = "${var.bastion_ami}"
  instance_type               = "${var.bastion_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.public.id}"]
  subnet_id                   = "${aws_subnet.public.id}"
  key_name                    = "${aws_key_pair.keypair.key_name}"
  associate_public_ip_address = true
}
