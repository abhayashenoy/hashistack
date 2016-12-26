data "template_file" "host_managers" {
  template = <<EOF
manager-${index}
EOF
  count = "${var.manager_count}"
  vars = {
    index = "${count.index}"
  }
}

data "template_file" "host_workers" {
  template = <<EOF
worker-${index}
EOF
  count = "${var.worker_count}"
  vars = {
    index = "${count.index}"
  }
}

data "template_file" "host_bastion" {
  template = <<EOF
bastion
EOF
}

data "template_file" "host_cfg" {
  template = <<EOF
${manager_hosts}
${worker_hosts}
${bastion_host}
EOF
  vars = {
    worker_hosts = "${join("", data.template_file.host_managers.*.rendered)}"
    manager_hosts = "${join("", data.template_file.host_workers.*.rendered)}"
    bastion_host = "${data.template_file.host_bastion.rendered}"
  }
}

resource "null_resource" "ssh_cfg" {
  triggers = {
    any = "${join(",", concat(aws_instance.workers.*.id, aws_instance.managers.*.id, aws_instance.bastion.*.id))}"
  }
  provisioner "local-exec" {
    command = "echo \"${data.template_file.host_cfg.rendered}\" > hosts"
  }
}
