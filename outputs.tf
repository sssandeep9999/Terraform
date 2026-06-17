# outputs for modules VPC and EKS
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# outputs for modules EC2 and IAM
# ec2
output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = module.ec2.instance_public_ip # public_ip is attribute
}

# iam 
output "instance_profile_name" {
  value = module.iam.instance_profile_name
}