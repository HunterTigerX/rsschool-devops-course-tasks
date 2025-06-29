output "s3_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state_bucket.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB lock table"
  value       = aws_dynamodb_table.terraform_state_locks.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = values(aws_subnet.private)[*].id
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = aws_instance.bastion.public_ip
}

output "k3s_server_private_ip" {
  description = "Private IP address of the K3s Server node"
  value       = aws_instance.k3s_server.private_ip
}

output "k3s_agent_private_ip" {
  description = "Private IP address of the K3s Agent node"
  value       = aws_instance.k3s_agent.private_ip
}

output "k3s_cluster_token" {
  description = "K3s cluster join token (sensitive)"
  value       = random_password.k3s_cluster_token.result
  sensitive   = true # Mark as sensitive to prevent display in console output [2, 3]
}

output "nat_gateway_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "kubectl_access_instructions" {
  description = "Instructions for accessing K3s cluster from local computer"
  value = <<-EOT
    To access the cluster from your local computer:
    
    1. SSH to bastion host:
       ssh -i your-key.pem ec2-user@${aws_instance.bastion.public_ip}
    
    2. From bastion, copy kubeconfig from K3s server:
       ssh -i your-key.pem ec2-user@${aws_instance.k3s_server.private_ip} "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s-config.yaml
    
    3. Edit k3s-config.yaml and replace 127.0.0.1 with ${aws_instance.k3s_server.private_ip}
    
    4. Set up port forwarding through bastion:
       ssh -i your-key.pem -L 6443:${aws_instance.k3s_server.private_ip}:6443 ec2-user@${aws_instance.bastion.public_ip}
    
    5. Use kubectl locally:
       export KUBECONFIG=./k3s-config.yaml
       kubectl get nodes
  EOT
}
