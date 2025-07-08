# K3s Cluster Deployment on AWS

## Overview
This project deploys a K3s Kubernetes cluster on AWS using Terraform, consisting of:
- 1 K3s Server node (control plane)
- 1 K3s Agent node (worker)
- 1 Bastion host for secure access
- VPC with public/private subnets
- NAT instance for private subnet internet access

## Architecture
- **VPC**: `10.0.0.0/16`
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24`
- **Private Subnets**: `10.0.3.0/24`, `10.0.4.0/24`
- **Bastion Host**: Public IP for SSH access
- **K3s Server**: Private subnet (10.0.3.200)
- **K3s Agent**: Private subnet (10.0.4.16)

## Deployment Steps

### 1. Prerequisites
- AWS CLI configured
- Terraform installed
- SSH key pair created in AWS

### 2. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 3. Access Cluster

#### From Bastion Host:
```bash
# SSH to bastion
ssh -i your-key.pem ec2-user@54.216.57.242

# From bastion, SSH to K3s server
ssh -i your-key.pem ec2-user@10.0.3.200

# Check cluster nodes
sudo kubectl get nodes

# Check all resources
sudo kubectl get all --all-namespaces
```

#### Deploy Test Workload:
```bash
# Deploy nginx pod
sudo kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml

# Verify deployment
sudo kubectl get pods
sudo kubectl get all --all-namespaces | grep nginx
```

## Security Features
- Private subnets for K3s nodes
- Security groups with minimal required ports
- Bastion host for secure access
- HTTPS-only S3 bucket policy
- Encrypted Terraform state

## Resources Created
- VPC with public/private subnets
- Internet Gateway and NAT instance
- Security groups for bastion, K3s server, and agent
- EC2 instances (bastion, K3s server, K3s agent)
- S3 bucket for Terraform state
- DynamoDB table for state locking

## Verification Commands
```bash
# Should show 2 nodes (server + agent)
sudo kubectl get nodes

# Should show nginx pod
sudo kubectl get all --all-namespaces
```

# Jenkins Deployment (Task 4)
## Helm Installation
1. Add Jenkins repository:

```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```
2. Create namespace:
```
bash
kubectl create namespace jenkins
```
3. Install Jenkins:

```bash
helm install jenkins jenkins/jenkins -n jenkins
```
4. Get admin password:

```bash
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /var/jenkins_home/secrets/initialAdminPassword
```
5. Access Jenkins UI:

```bash
# On your local machine (new terminal)
ssh -i your-key.pem -N -L 8080:<k3s_server_private_ip>:8080 ec2-user@<bastion_public_ip>
```
6. Then access Jenkins at http://localhost:8080

## CI/CD with GitHub Actions
The repository includes a pre-configured workflow (.github/workflows/terraform.yml) that:
- Uses OIDC for secure AWS authentication
- Automatically runs terraform plan for Pull Requests
- Executes terraform apply when merging to main branch

Verification Commands
```bash
# Cluster nodes
kubectl get nodes

# All resources
kubectl get all --all-namespaces

# Jenkins access
kubectl -n jenkins get pods
```
## Cost Optimization Highlights
- NAT Instance instead of NAT Gateway (saves ~$32/month)
- t4g.nano instances where possible (Free Tier eligible)
- Minimal resource footprint while maintaining production readiness

## Security Best Practices
- Private networking for cluster nodes
- Restricted SSH access via bastion only
- IAM roles instead of static credentials
- Encrypted state storage
- Least-privilege security group rules