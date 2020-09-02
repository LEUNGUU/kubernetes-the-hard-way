data "template_file" "k8s" {
  template = file("${path.module}/template/host.tpl")
  vars = {
    bastion = google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip
    kubernetes-controller = join("\n", google_compute_instance.controller.*.network_interface.0.network_ip)
    kubernetes-worker = join("\n", google_compute_instance.worker.*.network_interface.0.network_ip)
  }
}

resource "local_file" "inventory" {
  content = data.template_file.k8s.rendered
  filename = "${path.root}/../ansible/inventory/host"
}

# generate proxy variable file
data "template_file" "proxy" {
  template = file("${path.module}/template/all.tpl")
  vars = {
    https_proxy = "http://${google_compute_instance.bastion.network_interface.0.network_ip}:3128"
    http_proxy = "http://${google_compute_instance.bastion.network_interface.0.network_ip}:3128"
  }
}

resource "local_file" "groupvar" {
  content = data.template_file.proxy.rendered
  filename = "${path.root}/../ansible/group_vars/all.yml"
}
