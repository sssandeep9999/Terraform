# Internet Gateway (IGW)

## Overview

An Internet Gateway (IGW) is attached to the VPC to enable communication between resources inside the VPC and the public internet.

The Internet Gateway acts as the entry and exit point for internet traffic. Without an Internet Gateway, resources inside the VPC cannot communicate with the internet even if they have public IP addresses assigned.

### Terraform Implementation

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

### Architecture

```text
Internet
    |
    v
Internet Gateway
    |
    v
VPC
```

### Purpose

* Enables internet connectivity for public resources.
* Serves as the gateway between the VPC and the public internet.
* Required for public subnet internet access.
* Required for NAT Gateway outbound internet connectivity.

---

# Public Route Table

## Overview

A route table determines how network traffic is routed within the VPC.

To make a subnet public, a default route (`0.0.0.0/0`) must point to the Internet Gateway.

### Terraform Implementation

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
```

### Traffic Flow

```text
Public EC2 Instance
        |
        v
Public Route Table
        |
        v
Internet Gateway
        |
        v
Internet
```

### Purpose

* Provides internet access to public subnets.
* Allows resources with public IP addresses to communicate with the internet.
* Makes public subnets reachable from the internet when resources have public IP addresses assigned.
* Used by NAT Gateways to reach the internet.

# Elastic IP (EIP)

## Overview

A NAT Gateway requires a public IP address to communicate with the internet.

AWS provides this public IP through an Elastic IP (EIP), which is a static public IPv4 address allocated to your AWS account.

Each NAT Gateway must be associated with an Elastic IP. Without an Elastic IP, the NAT Gateway cannot provide internet access to resources running in private subnets.

### Terraform Implementation

```hcl
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"
}
```

### Architecture

```text
Private Subnet
      |
      v
NAT Gateway
      |
      v
Elastic IP
      |
      v
Internet Gateway
      |
      v
Internet
```

### Purpose

* Provides a public IP address for the NAT Gateway.
* Enables outbound internet communication from private subnets.
* Remains static even if infrastructure is recreated.
* Required for NAT Gateway internet connectivity.
* Supports production deployments with one Elastic IP per NAT Gateway.

# NAT Gateway Design

## Overview

This VPC module is designed to support both production and non-production environments. It follows AWS networking best practices by creating public and private subnets across multiple Availability Zones (AZs).

Private subnets do not have direct internet access. To allow resources in private subnets to download packages, pull container images, access AWS services, or communicate with external services, a NAT Gateway is required.

---

## Production Architecture (Recommended)

AWS recommends deploying **one NAT Gateway per Availability Zone (AZ)** instead of sharing a single NAT Gateway across all AZs.

For example, when deploying the VPC in the `ap-south-1` region:

```text
ap-south-1a
ap-south-1b
ap-south-1c
```

The architecture becomes:

```text
AZ-A
  Private Subnet A ---> NAT Gateway A

AZ-B
  Private Subnet B ---> NAT Gateway B

AZ-C
  Private Subnet C ---> NAT Gateway C
```

### Benefits

#### 1. High Availability

If NAT Gateway A or Availability Zone A becomes unavailable, workloads running in AZ-B and AZ-C continue to access the internet through their local NAT Gateways.

#### 2. Avoid Cross-AZ Data Transfer Charges

Traffic remains within the same Availability Zone and does not need to traverse another AZ to reach a NAT Gateway.

#### 3. Better Performance

Network traffic stays local to the Availability Zone, reducing latency and eliminating unnecessary network hops.

---

## Terraform Implementation

This module uses Terraform's `count` meta-argument to dynamically create NAT Gateways based on the number of public subnets (typically one public subnet per Availability Zone).

Example:

```hcl
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

### Relationship Between NAT Gateway and Elastic IP

Each NAT Gateway is associated with a dedicated Elastic IP.

Example:

```text
aws_eip.nat[0] ---> aws_nat_gateway.main[0]
aws_eip.nat[1] ---> aws_nat_gateway.main[1]
aws_eip.nat[2] ---> aws_nat_gateway.main[2]
```

For a deployment spanning three Availability Zones:

```text
ap-south-1a -> NAT Gateway A -> Elastic IP A
ap-south-1b -> NAT Gateway B -> Elastic IP B
ap-south-1c -> NAT Gateway C -> Elastic IP C
```

This ensures that each NAT Gateway has its own static public IP address for outbound internet communication.

If the deployment contains three public subnets:

```hcl
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]
```

Terraform calculates:

```hcl
count = 3
```

And creates:

```text
aws_nat_gateway.main[0] -> NAT Gateway in ap-south-1a
aws_nat_gateway.main[1] -> NAT Gateway in ap-south-1b
aws_nat_gateway.main[2] -> NAT Gateway in ap-south-1c
```

This automatically scales the NAT Gateway deployment based on the number of Availability Zones used by the VPC.

---

## Cost-Saving Architecture

For personal projects, development environments, labs, or learning purposes, a single NAT Gateway can be shared across all private subnets.

Architecture:

```text
AZ-A
  NAT Gateway A
      ^
      |
Private Subnet A (AZ-A)
Private Subnet B (AZ-B)
Private Subnet C (AZ-C)
```

### Benefits

* Lower infrastructure cost
* Only one NAT Gateway is billed

### Limitations

#### 1. Reduced High Availability

If the NAT Gateway or its Availability Zone becomes unavailable, all private subnets lose internet access.

#### 2. Cross-AZ Data Transfer Charges

Private subnets located in other Availability Zones must send traffic to the NAT Gateway in AZ-A, resulting in additional AWS charges.

#### 3. Potential Performance Impact

Traffic must traverse Availability Zones before reaching the internet.

---

## Design Decision

This module is designed for production-ready deployments and therefore creates **one NAT Gateway per Availability Zone** using Terraform's `count` functionality.

This approach provides:

* High Availability
* Better Fault Tolerance
* Improved Network Performance
* No Cross-AZ NAT Traffic Charges
* Alignment with AWS Best Practices

For cost-sensitive environments, the implementation can be modified to deploy a single shared NAT Gateway instead.

# Private Route Tables

## Overview

Private subnets should not have direct access to the Internet Gateway.

Instead, outbound internet traffic from private subnets is routed through a NAT Gateway.

Each private route table contains a default route (`0.0.0.0/0`) pointing to the NAT Gateway.

### Terraform Implementation

```hcl
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
}
```

> **Note:** This implementation assumes one NAT Gateway per Availability Zone and one private subnet per Availability Zone. Therefore, the number of private subnets should match the number of NAT Gateways created.

### Traffic Flow

```text
Private EC2 Instance
        |
        v
Private Route Table
        |
        v
NAT Gateway
        |
        v
Internet Gateway
        |
        v
Internet
```

### Purpose

* Allows private resources to access the internet securely.
* Prevents inbound internet access to private resources.
* Commonly used by EKS worker nodes, application servers, and backend services.

---
# Route Table Associations

## Overview

A route table only becomes effective when it is associated with a subnet.

This module associates:

* Public subnets with the Public Route Table.
* Private subnets with the Private Route Tables.

### Public Route Table Association

```hcl
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

### Private Route Table Association

```hcl
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

### Architecture

```text
Public Subnet
      |
      v
Public Route Table
      |
      v
Internet Gateway


Private Subnet
      |
      v
Private Route Table
      |
      v
NAT Gateway
      |
      v
Internet Gateway
```

### Purpose

* Associates subnets with the correct route tables.
* Enables internet access for public subnets through the Internet Gateway.
* Enables outbound internet access for private subnets through the NAT Gateway.
* Maintains proper network segmentation and security.

---

# Complete Network Flow

```text
Internet
    ^
    |
Internet Gateway
    ^
    |
NAT Gateway
    ^
    |
Private Route Table
    ^
    |
Private Subnet


Internet
    ^
    |
Internet Gateway
    ^
    |
Public Route Table
    ^
    |
Public Subnet
```

This design ensures that public resources can communicate directly with the internet, while private resources remain protected and use NAT Gateways for outbound internet connectivity.
