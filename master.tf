resource "cloudca_network" "master" {
  environment_id   = "${cloudca_environment.kubernetes.id}"
  name             = "${format("%s-network-master", var.prefix)}"
  description      = "Network for the master nodes"
  vpc_id           = "${cloudca_vpc.kubernetes.id}"
  network_offering = "Standard Tier"
  network_acl_id   = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl" "master" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  name           = "${format("%s-master-acl", var.prefix)}"
  description    = "Kubernetes ACL for the master node"
  vpc_id         = "${cloudca_vpc.kubernetes.id}"
}

resource "cloudca_network_acl_rule" "master_ssh" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 1
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 22
  end_port       = 22
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_dns_tcp" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 2
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 53
  end_port       = 53
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_dns_udp" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 3
  action         = "Allow"
  protocol       = "UDP"
  start_port     = 53
  end_port       = 53
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_kubernetes_api_server" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 101
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 6443
  end_port       = 6443
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_etc_server_client_api" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 102
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 2379
  end_port       = 2380
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_kubelet_api" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 103
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 10250
  end_port       = 10250
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_kube_scheduler" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 104
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 10251
  end_port       = 10251
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_kube_controller_manager" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 105
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 10252
  end_port       = 10252
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

resource "cloudca_network_acl_rule" "master_readonly_kubelet_api" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 106
  action         = "Allow"
  protocol       = "TCP"
  start_port     = 10255
  end_port       = 10255
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.master.id}"
}

# Add token to init script
data "template_file" "bootstrap_master" {
  template = "${file("templates/bootstrap_master.sh.tpl")}"

  vars {
    username     = "${var.username}"
    token        = "${local.token}"
    deploy_vault = "${var.deploy_vault ? "true" : "false"}"
  }
}

resource "cloudca_instance" "master_node" {
  environment_id         = "${cloudca_environment.kubernetes.id}"
  name                   = "${format("%s-master01", var.prefix)}"
  network_id             = "${cloudca_network.master.id}"
  template               = "${var.template_name}"
  compute_offering       = "${var.default_offering}"
  cpu_count              = "${var.master_vcpu}"
  memory_in_mb           = "${var.master_ram}"
  root_volume_size_in_gb = "${var.master_disk}"
  user_data              = "${data.template_file.cloudinit.rendered}"
}

resource "cloudca_port_forwarding_rule" "management_master_ssh" {
  environment_id     = "${cloudca_environment.kubernetes.id}"
  public_ip_id       = "${cloudca_public_ip.master_ip.id}"
  public_port_start  = "2200"
  private_ip_id      = "${cloudca_instance.master_node.private_ip_id}"
  private_port_start = 22
  protocol           = "TCP"

  connection {
    type        = "ssh"
    user        = "${var.username}"
    private_key = "${file("./id_rsa")}"
    host        = "${cloudca_public_ip.master_ip.ip_address}"
    port        = 2200
  }

  provisioner "file" {
    content     = "${data.template_file.bootstrap_master.rendered}"
    destination = "/home/${var.username}/bootstrap.sh"
  }

  provisioner "file" {
    source      = "manifests"
    destination = "/home/${var.username}/manifests"
  }
}
