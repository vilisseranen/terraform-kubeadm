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

resource "cloudca_public_ip" "master_ip" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  vpc_id         = "${cloudca_vpc.kubernetes.id}"
}

resource "cloudca_public_ip" "workers_ip" {
  environment_id = "${cloudca_environment.kubernetes.id}"
  vpc_id         = "${cloudca_vpc.kubernetes.id}"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh_key" {
  content  = "${tls_private_key.ssh_key.private_key_pem}"
  filename = "./id_rsa"
}

data "template_file" "cloudinit" {
  template = "${file("templates/cloudinit.tpl")}"

  vars {
    public_key = "${tls_private_key.ssh_key.public_key_openssh}"
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
  value = "${format("ssh %s@%s -p 2200 -i id_rsa", var.username, cloudca_public_ip.master_ip.ip_address)}"
}
