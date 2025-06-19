terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "huntertigerx3-terraform-state-bucket"
    key          = "global/s3/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2023 AMI
  instance_type               = "t3.micro"
  subnet_id                   = values(aws_subnet.public)[0].id # Place in first public subnet
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = "your-key-pair-name" # Replace with your key pair

  tags = merge(var.common_tags, { 
    Name = "bastion-host"
    Role = "bastion"
  })
}