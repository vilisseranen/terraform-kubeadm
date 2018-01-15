resource "cloudca_network" "worker" {
  environment_id   = "${cloudca_environment.kubernetes.id}"
  name             = "${format("%s-network-worker", var.prefix)}"
  description      = "Network for the worker nodes"
  vpc_id           = "${cloudca_vpc.kubernetes.id}"
  network_offering = "Load Balanced Tier"
  network_acl_id   = "${cloudca_network_acl.worker.id}"
}

resource "cloudca_network_acl" "worker" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  name           = "${format("%s-worker-acl", var.prefix)}"
  description    = "Kubernetes ACL for the worker nodes"
  vpc_id         = "${cloudca_vpc.kubernetes.id}"
}

resource "cloudca_network_acl_rule" "worker_ssh" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 1
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 22
  end_port       = 22
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.worker.id}"
}

resource "cloudca_network_acl_rule" "worker_kubelet_api" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 101
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 10250
  end_port       = 10250
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.worker.id}"
}

resource "cloudca_network_acl_rule" "worker_readonly_kubelet_api" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 102
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 10255
  end_port       = 10255
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.worker.id}"
}

resource "cloudca_network_acl_rule" "worker_nodeport_services" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 103
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 30000
  end_port       = 32767
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.worker.id}"
}

data "template_file" "bootstrap_worker" {
  template = "${file("templates/bootstrap_worker.sh.tpl")}"

  vars {
    username       = "${var.username}"
    token          = "${local.token}"
    master_node_ip = "${cloudca_instance.master_node.private_ip}"
  }
}

resource "cloudca_instance" "worker_nodes" {
  environment_id         = "${cloudca_environment.kubernetes.id}"
  name                   = "${format("%s-worker%02d", var.prefix, count.index + 1)}"
  network_id             = "${cloudca_network.worker.id}"
  template               = "${var.template_name}"
  compute_offering       = "${var.default_offering}"
  cpu_count              = "${var.worker_vcpu}"
  memory_in_mb           = "${var.worker_ram}"
  root_volume_size_in_gb = "${var.worker_disk}"
  count                  = "${var.worker_count}"
  user_data              = "${data.template_file.cloudinit.rendered}"
  depends_on             = ["cloudca_instance.master_node"]
}

resource "cloudca_port_forwarding_rule" "management_worker_ssh" {
  environment_id     = "${cloudca_environment.kubernetes.id}"
  public_ip_id       = "${cloudca_public_ip.workers_ip.id}"
  public_port_start  = "${2210 + count.index + 1}"
  private_ip_id      = "${element(cloudca_instance.worker_nodes.*.private_ip_id, count.index)}"
  private_port_start = 22
  protocol           = "TCP"
  count              = "${var.worker_count}"

  provisioner "file" {
    content     = "${data.template_file.bootstrap_worker.rendered}"
    destination = "/home/${var.username}/bootstrap.sh"

    connection {
      type        = "ssh"
      user        = "${var.username}"
      private_key = "${file("./id_rsa")}"
      host        = "${cloudca_public_ip.workers_ip.ip_address}"
      port        = "${2210 + count.index + 1}"
    }
  }
}
