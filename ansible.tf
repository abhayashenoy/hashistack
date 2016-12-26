data "template_file" "ansible_managers" {
  template = <<EOF
manager-${index} hostname=manager-${index}
EOF
  count = "${var.manager_count}"
  vars = {
    index = "${count.index}"
    ip = "${element(aws_instance.managers.*.private_ip, count.index)}"
  }
}

data "template_file" "ansible_workers" {
  template = <<EOF
worker-${index} hostname=worker-${index}
EOF
  count = "${var.worker_count}"
  vars = {
    index = "${count.index}"
    ip = "${element(aws_instance.workers.*.private_ip, count.index)}"
  }
}

data "template_file" "ansible_inventory" {
  template = <<EOF
[managers]
${managers}

[workers]
${workers}

[all:children]
managers
workers
EOF
  vars = {
    workers = "${join("", data.template_file.ansible_workers.*.rendered)}"
    managers = "${join("", data.template_file.ansible_managers.*.rendered)}"
  }
}

resource "null_resource" "ansible_inventory" {
  triggers = {
    any = "${join(",", concat(aws_instance.workers.*.id, aws_instance.managers.*.id, aws_instance.bastion.*.id))}"
  }
  provisioner "local-exec" {
    command = "echo \"${data.template_file.ansible_inventory.rendered}\" > inventory"
  }
}
