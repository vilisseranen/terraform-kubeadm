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

  provisioner "file" {
    content     = "${data.template_file.bootstrap_worker.rendered}"
    destination = "/home/${var.username}/bootstrap.sh"

    connection {
      type        = "ssh"
      host        = "${self.private_ip}"
      user        = "${var.username}"
      private_key = "${tls_private_key.ssh_key.private_key_pem}"
      port        = 22

      bastion_host        = "${cloudca_public_ip.bastion.ip_address}"
      bastion_user        = "${var.username}"
      bastion_private_key = "${tls_private_key.ssh_key.private_key_pem}"
      bastion_port        = 22
    }
  }
}
