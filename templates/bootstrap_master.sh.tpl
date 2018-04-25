#!/usr/bin/env bash

export PYTHONIOENCODING=utf8

# Variables to upload join script to swift
# Init the master
echo "Init the master"
kubeadm init --apiserver-cert-extra-sans ${cert_ip} --token ${token} >> /home/${username}/kubeadm_init.log

# Config kubectl
echo "Copy config"
mkdir -p /home/${username}/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/${username}/.kube/config
sudo chown ${username}:${username} /home/${username}/.kube/config

# Create network overlay
echo "Create network overlay"
sleep 60
kubever=$(kubectl version | base64 | tr -d '\n')
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

# Deploy a Dashboard
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

# Create the Vault deployment
if ${deploy_vault}
then
  kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f /home/${username}/manifests/vault.yaml
fi
