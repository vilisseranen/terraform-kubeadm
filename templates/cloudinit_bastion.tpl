#cloud-config

package_upgrade: true

packages:
  - vim
  - bash-completion

users:
  - name: cca-user
    lock_passwd: true
  - name: ${username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - "${public_key}"
yum_repos:
    kubernetes:
      name: Kubernetes
      baseurl: https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
      enabled: true
      gpgcheck: true
      gpgkey: https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

runcmd:
  - yum install -y kubectl tmux
