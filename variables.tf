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