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

# Task 5: Flask Application Deployment with Helm

## Overview
This task demonstrates deploying a simple Flask application to a K3s Kubernetes cluster using Helm charts. The application is containerized with Docker and deployed using Kubernetes best practices.

## Application Architecture
- **Flask Application**: Simple "Hello, World!" web service
- **Container**: Python 3.9-slim based Docker image
- **Kubernetes Deployment**: Managed via Helm chart
- **Service**: ClusterIP service exposing port 8080
- **Ingress**: Traefik ingress for external access

## Prerequisites
- K3s cluster running (from previous tasks)
- Helm installed on the cluster
- Docker for building images
- Access to bastion host and K3s server

## Project Structure
```
├── main.py                    # Flask application
├── requirements.txt           # Python dependencies
├── Dockerfile                # Container definition
├── flask-helm-chart/         # Helm chart directory
│   ├── Chart.yaml            # Chart metadata
│   ├── values.yaml           # Default values
│   └── templates/            # Kubernetes templates
│       ├── deployment.yaml   # Deployment configuration
│       ├── service.yaml      # Service configuration
│       ├── ingress.yaml      # Ingress configuration
│       └── ...
└── TASK_5_README.md          # This documentation
```

## Deployment Steps

### 1. Build and Push Docker Image
```bash
# Build the Docker image
docker build -t huntertigerx/flask-app:latest .

# Push to Docker Hub (or your registry)
docker push huntertigerx/flask-app:latest
```

### 2. Access K3s Cluster
```bash
# SSH to bastion host
ssh -i your-key.pem ec2-user@<bastion-public-ip>

# SSH to K3s server from bastion
ssh -i your-key.pem ec2-user@10.0.3.200

# Verify cluster is running
sudo kubectl get nodes
```

### 3. Install Helm (if not already installed)
```bash
# Download and install Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Verify installation
helm version
```

### 4. Deploy Application with Helm
```bash
# Navigate to the chart directory
cd flask-helm-chart/

# Install the application
helm install flask-app . --namespace default

# Verify deployment
kubectl get pods
kubectl get services
kubectl get ingress
```

### 5. Access the Application

#### Option 1: Port Forward (for testing)
```bash
# Forward local port to service
kubectl port-forward service/flask-helm-chart 8080:8080

# Access via localhost (from another terminal)
curl http://localhost:8080
```

#### Option 2: Via Ingress (recommended)
```bash
# Check ingress configuration
kubectl get ingress

# Add entry to /etc/hosts on your local machine
echo "<k3s-server-ip> flask-app.local" >> /etc/hosts

# Access via browser or curl
curl http://flask-app.local
```

## Helm Chart Configuration

### Chart.yaml
- **Name**: flask-helm-chart
- **Version**: 0.1.0
- **App Version**: 1.16.0
- **Type**: application

### Key Values (values.yaml)
- **Replica Count**: 2 (for high availability)
- **Image**: huntertigerx/flask-app:latest
- **Service Type**: ClusterIP
- **Port**: 8080
- **Ingress**: Enabled with Traefik
- **Host**: flask-app.local

## Verification Commands

### Check Deployment Status
```bash
# View all resources
kubectl get all

# Check pod logs
kubectl logs -l app.kubernetes.io/name=flask-helm-chart

# Describe deployment
kubectl describe deployment flask-helm-chart
```

### Test Application
```bash
# Test via service
kubectl exec -it <pod-name> -- curl http://localhost:8080

# Test via ingress (if configured)
curl -H "Host: flask-app.local" http://<k3s-server-ip>
```

### Helm Management
```bash
# List installed releases
helm list

# Upgrade release
helm upgrade flask-app . --namespace default

# Uninstall release
helm uninstall flask-app --namespace default
```

## Troubleshooting

### Common Issues
1. **Image Pull Errors**: Ensure Docker image is publicly accessible
2. **Ingress Not Working**: Check Traefik is running and configured
3. **Pod Not Starting**: Check resource limits and image availability

### Debug Commands
```bash
# Check pod events
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# Check service endpoints
kubectl get endpoints

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup flask-helm-chart
```

## Security Considerations
- Application runs on non-privileged port (8080)
- Service account with minimal permissions
- Resource limits can be configured
- Ingress with proper host-based routing

## Customization Options

### Scaling
```bash
# Scale deployment
kubectl scale deployment flask-helm-chart --replicas=3

# Or update values.yaml and upgrade
helm upgrade flask-app . --set replicaCount=3
```

### Resource Limits
Update values.yaml:
```yaml
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
```

### Environment Variables
Add to deployment template:
```yaml
env:
- name: FLASK_ENV
  value: "production"
```

## Cleanup
```bash
# Remove Helm release
helm uninstall flask-app

# Remove Docker image (optional)
docker rmi huntertigerx/flask-app:latest
```
