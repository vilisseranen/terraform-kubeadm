provider "cloudca" {
  api_key = "${var.api_key}"
}

resource "cloudca_environment" "kubernetes" {
  service_code      = "${var.service_code}"
  organization_code = "${var.organization_code}"
  name              = "${format("%s-env", var.prefix)}"
  description       = "Environment for a Kubernetes cluster"
  admin_role        = ["${var.admin}"]
  read_only_role    = ["${var.read_only}"]
}

resource "cloudca_vpc" "kubernetes" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  name           = "${format("%s-vpc", var.prefix)}"
  description    = "VPC for a Kubernetes cluster"
  vpc_offering   = "Default VPC offering"
  zone           = "${var.zone_id}"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh_key_private" {
  content  = "${tls_private_key.ssh_key.private_key_pem}"
  filename = "./id_rsa"

  provisioner "local-exec" {
    command = "chmod 400 ./id_rsa"
  }
}

resource "local_file" "ssh_key_public" {
  content  = "${tls_private_key.ssh_key.public_key_openssh}"
  filename = "./id_rsa.pub"
}

data "template_file" "cloudinit" {
  template = "${file("templates/cloudinit.tpl")}"

  vars {
    public_key = "${replace(tls_private_key.ssh_key.public_key_openssh, "\n", "")}"
    username   = "${var.username}"
  }
}

data "template_file" "cloudinit_bastion" {
  template = "${file("templates/cloudinit_bastion.tpl")}"

  vars {
    public_key = "${replace(tls_private_key.ssh_key.public_key_openssh, "\n", "")}"
    username   = "${var.username}"
  }
}

data "template_file" "vault" {
  template = "${file("templates/vault.yaml.tpl")}"

  vars {
    os_username = "${var.os_username}"
    os_project  = "${var.os_project}"
    os_password = "${var.os_password}"
    os_auth_url = "${var.os_auth_url}"
    container   = "${var.container}"
  }

  count = "${var.deploy_vault ? 1 : 0}"
}

resource "local_file" "manifest_vault" {
  content  = "${data.template_file.vault.rendered}"
  filename = "manifests/vault.yaml"
  count    = "${var.deploy_vault ? 1 : 0}"
}

resource "random_string" "token" {
  length  = 23
  upper   = false
  special = false
}

locals {
  token = "${replace(random_string.token.result, "/^(.{6})(.{1})(.{16})$/", "$1.$3")}"
}

output "management_ip" {
  value = "${format("ssh %s@%s -i id_rsa", var.username, cloudca_public_ip.bastion.ip_address)}"
}
