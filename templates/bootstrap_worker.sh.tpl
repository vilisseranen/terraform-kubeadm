#!/bin/env bash


# JOIN CMD
kubeadm join --token ${token} ${master_node_ip}:6443 --discovery-token-unsafe-skip-ca-verification >> /home/${username}/kubeadm_join.log
