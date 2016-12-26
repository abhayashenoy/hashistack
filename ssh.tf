data "template_file" "ssh_managers" {
  template = <<EOF
Host manager-${index}
  Hostname ${ip}
  StrictHostKeyChecking no
EOF
  count = "${var.manager_count}"
  vars = {
    index = "${count.index}"
    ip = "${element(aws_instance.managers.*.private_ip, count.index)}"
  }
}

data "template_file" "ssh_workers" {
  template = <<EOF
Host worker-${index}
  Hostname ${ip}
  StrictHostKeyChecking no
EOF
  count = "${var.worker_count}"
  vars = {
    index = "${count.index}"
    ip = "${element(aws_instance.workers.*.private_ip, count.index)}"
  }
}

data "template_file" "ssh_bastion" {
  template = <<EOF
Host bastion
  Hostname ${ip}
  StrictHostKeyChecking no
  ProxyCommand none
  LocalForward 8200 ${manager}:8200
  LocalForward 8400 ${manager}:8400
  LocalForward 8500 ${manager}:8500
  LocalForward 4646 ${manager}:4646
  LocalForward 4647 ${manager}:4647
  LocalForward 4648 ${manager}:4648
  LocalForward 9999 ${worker}:9999
EOF
  vars = {
    ip = "${aws_instance.bastion.public_ip}"
    manager = "${aws_instance.managers.0.private_ip}"
    worker = "${aws_instance.workers.0.private_ip}"
  }
}

data "template_file" "ssh_cfg" {
  template = <<EOF
${manager_hosts}
${worker_hosts}
${bastion_host}

Host *
  ServerAliveInterval    60
  TCPKeepAlive           yes
  ProxyCommand           ssh -q -A ubuntu@${bastion_ip} nc %h %p
  ControlMaster          auto
  ControlPath            ~/.ssh/mux-%r@%h:%p
  ControlPersist         15m
  User                   ubuntu
  IdentityFile           id_rsa
EOF
  vars = {
    worker_hosts = "${join("\n", data.template_file.ssh_managers.*.rendered)}"
    manager_hosts = "${join("\n", data.template_file.ssh_workers.*.rendered)}"
    bastion_host = "${data.template_file.ssh_bastion.rendered}"
    bastion_ip = "${aws_instance.bastion.public_ip}"
  }
}

resource "null_resource" "ssh_cfg_setup" {
  triggers = {
    any = "${join(",", concat(aws_instance.workers.*.id, aws_instance.managers.*.id, aws_instance.bastion.*.id))}"
  }
  provisioner "local-exec" {
    command = "echo \"${data.template_file.ssh_cfg.rendered}\" > ssh.cfg"
  }
}
