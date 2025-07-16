terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  // Бэкенд для хранения состояния Terraform в S3.
  // Это лучшая практика для командной работы и безопасности.
  /*
  backend "s3" {
    bucket         = "huntertigerx-terraform-state-k3s-eu-west-1" 
    key            = "global/k3s-cluster/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
  */
}

provider "aws" {
  region = var.aws_region
}