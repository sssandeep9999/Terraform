# ec2
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}


variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}


variable "subnet_id" {
  description = "Subnet ID to launch the EC2 instance"
  type        = string
}


variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

# iam
variable "iam_instance_profile" {
  type = string
}