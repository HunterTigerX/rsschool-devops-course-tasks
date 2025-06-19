# AWS Infrastructure Setup

## VPN
If you live in Russia or Belarus, you need to enable VPN connection.  
Also among the prequesities are [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform).  

## Overview
This Terraform configuration sets up a VPC with public and private subnets, including:
- Security groups for internal traffic, bastion host, and NAT instance
- Bastion host for secure SSH access to private instances
- NAT instance for outbound internet access from private subnets
- S3 bucket for Terraform state storage
- DynamoDB table for state locking

## Components

### Networking
- VPC with CIDR: ${var.vpc_cidr}
- Public subnets: ${join(", ", [for s in var.public_subnets : s.cidr])}
- Private subnets: ${join(", ", [for s in var.private_subnets : s.cidr])}
- Internet Gateway
- Route tables for public and private subnets

### Security
- Internal traffic security group (allows all within VPC)
- Bastion host security group (SSH access)
- NAT instance security group

### Access
- Bastion host: ssh ec2-user@${aws_instance.bastion.public_ip}
- Private instances: Connect via bastion host

### NAT Configuration
The NAT instance provides outbound internet access for private subnets at ~$3.5/month (vs $32/month for NAT Gateway).

## Usage  
You can run `terraform init` to create an S3 bucket and a DynamoDB table to store the state. At this stage, the state is still stored locally.  
Then you can run `terraform plan` to compares the current state of the infrastructure, check the syntax and validity and to show the change plan wwithout actually implementing it.  
Then you can run `terraform apply` to create the resources and start storing the state in an S3 bucket.  
At `.github\workflows\terraform-ci.yml` you can see the github actions config.  