# Terraform AWS Infrastructure

This repository contains the Terraform configuration used to provision the AWS infrastructure for the Spring PetClinic DevOps implementation.

The infrastructure includes an Amazon VPC, public and private subnets, networking components, Amazon EKS, managed node groups, IAM roles and policies, and an EC2 instance.

## Architecture

```text
                         AWS
                          |
                         VPC
                     10.0.0.0/16
                          |
              +-----------+-----------+
              |                       |
        Public Subnets          Private Subnets
        3 Availability Zones    3 Availability Zones
              |                       |
       Internet Gateway          EKS Cluster
              |                       |
         NAT Gateway             EKS Node Group
              |                       |
             EC2              Kubernetes Workloads
```

## Terraform Module Structure

```text
Terraform/
├── main.tf
├── provider.tf
├── versions.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
│
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    │
    ├── eks/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── iam/
    │   ├── role.tf
    │   ├── policy.tf
    │   ├── instance-profile.tf
    │   └── outputs.tf
    │
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── output.tf
```

## Infrastructure Components

### VPC

The VPC module provisions:

* VPC with CIDR `10.0.0.0/16`
* Three Availability Zones
* Three public subnets
* Three private subnets
* Internet Gateway
* NAT Gateway
* Public route table
* Private route tables
* Route table associations

The current configuration uses a single NAT Gateway in the first public subnet. Private subnets route outbound internet traffic through this NAT Gateway.

### Amazon EKS

The EKS module provisions:

* Amazon EKS cluster
* EKS cluster IAM role
* EKS Cluster Policy
* Managed EKS node group
* EKS worker-node IAM role
* Amazon EKS Worker Node Policy
* Amazon VPC CNI Policy
* Amazon ECR read-only access

The Kubernetes version and node-group configuration are controlled through Terraform variables.

### EKS Node Group

The node group supports configurable:

* EC2 instance types
* Capacity type
* Minimum node count
* Desired node count
* Maximum node count

The default configuration uses:

```text
Instance type : t3.medium
Capacity type : ON_DEMAND
Minimum       : 1
Desired       : 2
Maximum       : 4
```

### IAM

The IAM module provides an EC2 IAM role with:

* AmazonSSMManagedInstanceCore policy
* EC2 instance profile

The instance profile is passed from the IAM module to the EC2 module.

### EC2

The EC2 module provisions an EC2 instance using configurable:

* AMI ID
* Instance type
* Subnet
* Instance name
* IAM instance profile

## Terraform State

Terraform uses an Amazon S3 backend for remote state storage.

The backend configuration uses:

```text
S3 bucket : demo-terraform-eks-state-s3-bucket-9
Region    : ap-south-1
State     : terraform.tfstate
Locking   : S3 lockfile
```

Sensitive or environment-specific Terraform values should be managed outside source control where appropriate.

## Variables

The infrastructure is parameterized using Terraform variables for:

* AWS region
* VPC CIDR
* Availability Zones
* Public subnet CIDRs
* Private subnet CIDRs
* EKS cluster name
* Kubernetes version
* EKS node groups
* EC2 AMI
* EC2 instance type
* EC2 instance name

## Outputs

The Terraform configuration exposes outputs including:

* EKS cluster endpoint
* EKS cluster name
* VPC ID
* EC2 public IP
* EC2 instance profile name

## Terraform Workflow

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Format Terraform files:

```bash
terraform fmt -recursive
```

Review the planned infrastructure changes:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

Destroy the infrastructure when it is no longer required:

```bash
terraform destroy
```

## Relationship with Spring PetClinic

This repository provisions the AWS infrastructure used by the Spring PetClinic DevOps project.

The application repository contains the application, CI/CD pipelines, Kubernetes manifests, monitoring documentation, and security documentation.

Spring PetClinic DevOps repository:

https://github.com/sssandeep9999/spring-petclinic-devops

Terraform infrastructure repository:

https://github.com/sssandeep9999/Terraform
