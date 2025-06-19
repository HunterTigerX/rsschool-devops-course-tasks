variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name" {
  description = "Name for the Terraform state S3 bucket"
  type        = string
  default     = "huntertigerx3-terraform-state-bucket"
}

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB lock table"
  type        = string
  default     = "terraform-state-locks"
}

variable "aws_account_id" {
  description = "AWS account ID for bucket policy"
  type        = string
  default     = "218585377303"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "Dev"
    Terraform   = "true"
  }
}

variable "enable_bucket_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets with their CIDR blocks and AZs"
  type        = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "public-subnet-1" = {
      cidr = "10.0.1.0/24"
      az   = "eu-west-1a"
    }
    "public-subnet-2" = {
      cidr = "10.0.2.0/24"
      az   = "eu-west-1b"
    }
  }
}

variable "private_subnets" {
  description = "Map of private subnets with their CIDR blocks and AZs"
  type        = map(object({
    cidr = string
    az   = string
  }))
  default = {
    "private-subnet-1" = {
      cidr = "10.0.3.0/24"
      az   = "eu-west-1a"
    }
    "private-subnet-2" = {
      cidr = "10.0.4.0/24"
      az   = "eu-west-1b"
    }
  }
}