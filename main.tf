terraform {
  backend "s3" {
    bucket         = "huntertigerx3-terraform-state-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-1"
    assume_role = {
      role_arn = "arn:aws:iam::218585377303:role/GithubActionsRole"
    }
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}