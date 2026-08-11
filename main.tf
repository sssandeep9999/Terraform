
terraform {
  backend "s3" {
    bucket = "demo-terraform-eks-state-s3-bucket-9"
    key    = "terraform.tfstate"
    region = "ap-south-1"
    # dynamodb_table = "terraform-eks-state-locks"
    # encrypt        = true
    use_lockfile = true
  }
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_name         = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups     = var.node_groups
}

module "iam" {
  source = "./modules/iam"

}

module "ec2" {
  source = "./modules/ec2"

  aws_region    = var.aws_region
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnet_ids[0]
  instance_name = var.instance_name

  iam_instance_profile = module.iam.instance_profile_name # This takes the output from the IAM module and passes it to the EC2 module.
}