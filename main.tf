terraform {
  backend "s3" {
    bucket         = "huntertigerx3-terraform-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locks"
  }
}