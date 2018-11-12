resource "cloudca_network" "public" {
  environment_id   = "${cloudca_environment.kubernetes.id}"
  name             = "${format("%s-network-public", var.prefix)}"
  description      = "Network for the public access"
  vpc_id           = "${cloudca_vpc.kubernetes.id}"
  network_offering = "Standard Tier"
  network_acl   = "${cloudca_network_acl.public.id}"
}

resource "cloudca_network_acl" "public" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  name           = "${format("%s-public-acl", var.prefix)}"
  description    = "Kubernetes ACL for public access"
  vpc_id         = "${cloudca_vpc.kubernetes.id}"
}

resource "cloudca_network_acl_rule" "public_in" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 50
  action         = "Allow"
  protocol       = "All"
  cidr           = "0.0.0.0/0"
  traffic_type   = "Ingress"
  network_acl_id = "${cloudca_network_acl.public.id}"
}

resource "cloudca_network_acl_rule" "public_out" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  rule_number    = 60
  action         = "Allow"
  protocol       = "All"
  cidr           = "0.0.0.0/0"
  traffic_type   = "Egress"
  network_acl_id = "${cloudca_network_acl.public.id}"
}

resource "cloudca_instance" "bastion" {
  environment_id         = "${cloudca_environment.kubernetes.id}"
  name                   = "${format("%s-bastion01", var.prefix)}"
  network_id             = "${cloudca_network.worker.id}"
  template               = "${var.template_name}"
  compute_offering       = "${var.default_offering}"
  cpu_count              = "1"
  memory_in_mb           = "1024"
  root_volume_size_in_gb = "8"
  user_data              = "${data.template_file.cloudinit_bastion.rendered}"
}

resource "cloudca_public_ip" "bastion" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  vpc_id         = "${cloudca_vpc.kubernetes.id}"
}

resource "cloudca_port_forwarding_rule" "bastion_ssh" {
  environment_id     = "${cloudca_environment.kubernetes.id}"
  public_ip_id       = "${cloudca_public_ip.bastion.id}"
  public_port_start  = "22"
  private_ip_id      = "${cloudca_instance.bastion.private_ip_id}"
  private_port_start = 22
  protocol           = "TCP"
}


resource "null_resource" "test_bastion" {
  provisioner "remote-exec" {
    inline = [ "ls" ]
  }

  provisioner "file" {
    content      = "${tls_private_key.ssh_key.private_key_pem}"
    destination = "/home/${var.username}/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
        "mkdir -p /home/${var.username}/.kube",
        "chmod 400 /home/${var.username}/.ssh/id_rsa"
    ]
  }

  connection {
    type        = "ssh"
    host        = "${cloudca_public_ip.bastion.ip_address}"
    user        = "${var.username}"
    private_key = "${tls_private_key.ssh_key.private_key_pem}"
    port        = 22
  }

}
