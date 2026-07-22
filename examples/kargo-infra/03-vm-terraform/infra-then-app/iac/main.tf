# Terraform for the infra dependency the app needs (an S3 bucket). Stubbed —
# replace with the real bucket resource. Targeted by the bundle's tf-apply step.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "bucket_name" { type = string }

# resource "aws_s3_bucket" "app_data" {
#   bucket = var.bucket_name
# }

output "bucket_name" {
  value = var.bucket_name
}
