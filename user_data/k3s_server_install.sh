#!/bin/bash
set -e
exec > >(tee /tmp/k3s-server-install.log) 2>&1

# Install K3s server with kubeconfig permissions and cluster-init
# K3S_KUBECONFIG_MODE="644" ensures /etc/rancher/k3s/k3s.yaml is readable by all [10, 11]
# --cluster-init initializes the first server in a new cluster [10]
# K3S_TOKEN is passed securely from Terraform [10]
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server --cluster-init --write-kubeconfig-mode 0644" K3S_TOKEN="${k3s_token}" sh -

# Make KUBECONFIG environment variable persistent for all users
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" | sudo tee -a /etc/profile.d/k3s.sh