If you live in Russia or Belarus, you need to enable VPN connection.  
Also among the prequesities are [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform).  
You can run `terraform init` to create an S3 bucket and a DynamoDB table to store the state. At this stage, the state is still stored locally.  
Then you can run `terraform plan` to compares the current state of the infrastructure, check the syntax and validity and to show the change plan wwithout actually implementing it.  
Then you can run `terraform apply` to create the resources and start storing the state in an S3 bucket.  
At `.github\workflows\terraform-ci.yml` you can see the github actions config.  
And at the `backend` folder you can see the implementation without using the terraform, just in case.


