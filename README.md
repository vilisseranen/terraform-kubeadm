# Kubernetes deployment on cloud.ca with `Terraform` and `kubeadm`

This configuration will deploy a Kubernetes cluster with:
- one master
- some workers
- a Weave Net pod network

The configuration was built from the instructions found on this page:
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

## How to use

- Generate ssh keys, with `ssh-keygen -t rsa -b 4096 -N "" -f ./id_rsa` for example
- Create a file terraform.tfvars containing at least the following variables:
  - `api_key`: your cloud.ca API key
  - `organization_code`: name used to connect to cloud.ca - \<organization_code>.cloud.ca
  - `service_code`: `compute-qc` or `compute-on`
  - `zone_id`: `QC-1` or `QC-2` when using `compute-qc`, `ON-1` when using `compute-on`
  - `admin`: a list of users in your organization who will have the `Environment Admin` role
  - `read_only`: a list of users in your organization who wil have the `Read Only` role
  - `prefix`: a prefix for all resources created
  - `username`: the username you will use to connect to the machines
- Initialize Terraform using `terraform init`

## Use Kubernetes

Terraform will output a command to connect to the master node at the end of the run.
The Kubernetes configuration was copied on the master node to the user's home directory.
With this user, you should be able to run `kubectl` commands. For example, at the end of
the Terraform run, try executing `kubectl get nodes` to see if all workers have joined
the cluster successfully, and `kubectl get pods --namespace kube-system` to make sure all
system components started properly (give it time, it takes a few minutes to fully
initialize).

## Kubernetes resource creation example

This configuration also contains the necessary configuration to create a basic Vault deployment.
If you want to create the Vault deployment, you will need to:
- Create an Object Storage environment, and a container
- Specify the following values in terraform.tfvars:
  - `os_username`: Object storage `User name` in cloud.ca
  - `os_project`: Object Storage `Tenant name` in cloud.ca
  - `os_password`: Object Storage `Password` in cloud.ca
  - `os_auth_url`: Object Storage `Authentication endpoint` in cloud.ca
  - `container`: Container used to store Vault data
  - `deploy_vault`: Set this to true
This will write a `vault.yaml` manifest in the `manifests/` folder, upload it to the
Kubernetes cluster and start the deployment. You will need to take care of the Vault
initialization. Note that this manifest will create 3 replicas of a non-HA Vault servers
connected to the same storage backend. You can access this container by creating a public IP and a
load balancing rule that will redirect requests to the right NodePort that was reserved by Kubernetes.

- `kubectl get deployments` will show the deployment
- `kubectl get pods -o wide` will show the 3 replicas of the vault pods
- `kubectl get svc -l app-vault` will show the node port that was assign for this deployment
