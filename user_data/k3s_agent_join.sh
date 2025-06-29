#!/bin/bash
set -e
exec > >(tee /tmp/k3s-agent-join.log) 2>&1

# Install K3s agent and join it to the server
# K3S_URL points to the K3s server's private IP on port 6443 [1, 10]
# K3S_TOKEN is passed securely from Terraform [10]
curl -sfL https://get.k3s.io | K3S_URL="https://${k3s_server_private_ip}:6443" K3S_TOKEN="${k3s_token}" sh -