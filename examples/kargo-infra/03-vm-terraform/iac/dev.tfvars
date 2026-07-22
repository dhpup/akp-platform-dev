# Sample IaC input the Warehouse watches. A commit here (e.g. bumping
# instance_count or ami_id) is the git-driven trigger that cuts Freight.
instance_count = 3
instance_type  = "t3.large"
ami_id         = "ami-0123456789abcdef0"
