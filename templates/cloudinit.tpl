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
    docker-main:
      name: Docker Repository
      baseurl: https://yum.dockerproject.org/repo/main/centos/7/
      enabled: true
      gpgcheck: true
      gpgkey: https://yum.dockerproject.org/gpg
    kubernetes:
      name: Kubernetes
      baseurl: https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
      enabled: true
      gpgcheck: true
      gpgkey: https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

runcmd:
  - systemctl stop firewalld
  - systemctl disable firewalld
  - setenforce 0
  - "sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config"
  - yum install -y docker-engine
  - systemctl enable docker
  - systemctl start docker
  - yum install -y kubelet kubeadm kubectl
  - echo -e "net.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/k8s.conf
  - sysctl --system
  - sed -i 's/Environment="KUBELET_CGROUP_ARGS=.*/Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=cgroupfs"/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  - systemctl daemon-reload
  - systemctl enable kubelet && systemctl start kubelet
  - echo "source <(kubectl completion bash)" >> /home/${username}/.bashrc
  - sleep 60
  - sh /home/${username}/bootstrap.sh
