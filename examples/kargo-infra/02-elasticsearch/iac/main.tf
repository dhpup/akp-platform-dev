# Minimal Terraform config the `tf-apply` step targets to provision ES data
# nodes. Stubbed to the essential shape — replace the resource block with your
# real module/provider. node_count is driven per-stage by the promotion.
terraform {
  # Configure a remote backend so state is shared with the runner/agent.
  # backend "s3" { bucket = "..." key = "es/${terraform.workspace}" region = "..." }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "node_count" {
  type        = number
  description = "Desired number of Elasticsearch data nodes."
}

# Placeholder for the real node resource (ASG / instances / cloud ES nodes).
# resource "aws_instance" "es_data" {
#   count = var.node_count
#   ...
# }

output "node_count" {
  value = var.node_count
}
