# Terraform the tf-plan/tf-apply steps target. Stubbed to the essential shape —
# replace the resource block with your real VM module/provider. Inputs come from
# <stage>.tfvars (see dev.tfvars).
terraform {
  # backend "s3" { bucket = "..." key = "vm/${terraform.workspace}" region = "..." }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "instance_count" { type = number }
variable "instance_type" { type = string }
variable "ami_id" { type = string }

# resource "aws_instance" "vm" {
#   count         = var.instance_count
#   instance_type = var.instance_type
#   ami           = var.ami_id
# }

output "vm_health_url" {
  # A real module would output the load balancer / canary URL here.
  value = "https://vm-canary.internal/healthz"
}
