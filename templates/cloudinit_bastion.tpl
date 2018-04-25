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

