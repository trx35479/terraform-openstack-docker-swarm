# Template to generate dynamic IP address of nodes

data "template_file" "dynamic_inventory" {
  template = "${file("templates/inventory.tpl")}"

  depends_on = [
    "module.fips",
    "module.network",
    "module.manager",
    "module.standby",
    "module.worker",
    "module.loadbalancer",
  ]

  vars {
    manager          = "${join("\n", module.fips.manager_fips)}"
    standby-managers = "${join("\n", module.fips.standby_fips)}"
    workers          = "${join("\n", module.fips.worker_fips)}"
  }
}

resource "null_resource" "trigger" {
  triggers {
    template_rendered = "${data.template_file.dynamic_inventory.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.dynamic_inventory.rendered}' > inventory"
  }
}

# Get the private IP addres of the master node to be usd during joining the node

data "template_file" "get_private_ip" {
  template = "${file("templates/manager_ip.tpl")}"

  depends_on = [
    "module.fips",
    "module.network",
    "module.manager",
    "module.standby",
    "module.worker",
    "module.loadbalancer",
  ]

  vars {
    python_interpreter = "${var.IMAGE_NAME == "coreOS" ? "/opt/bin/python" : "/usr/bin/python"}"
    manager_ip         = "${element(module.manager.private_ip, 0)}"
  }
}

resource "null_resource" "update_group_vars" {
  triggers {
    template_rendered = "${data.template_file.get_private_ip.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.get_private_ip.rendered}' > group_vars/all.yaml"
  }
}
