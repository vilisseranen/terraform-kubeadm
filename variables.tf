variable "api_key" {}

variable "service_code" {}

variable "organization_code" {}

variable "admin" {
  type = "list"
}

variable "read_only" {
  type = "list"
}

variable "zone_id" {}

variable "prefix" {}

variable "username" {}

variable "worker_count" {
  default = 3
}

variable "template_name" {
  default = "CentOS 7.4 HVM"
}

variable "default_offering" {
  default = "Custom specs on VDI-per-LUN"
}

variable "master_ram" {
  default = 4096
}

variable "master_vcpu" {
  default = 2
}

variable "master_disk" {
  default = 20
}

variable "worker_ram" {
  default = 8192
}

variable "worker_vcpu" {
  default = 4
}

variable "worker_disk" {
  default = 20
}

# Configuration for the Vault deployment
variable "deploy_vault" {
  default = false
}

variable "os_username" {}
variable "os_project" {}
variable "os_password" {}
variable "os_auth_url" {}
variable "container" {}
