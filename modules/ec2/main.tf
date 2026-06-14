resource "aws_instance" "example" {
  ami           = var.ami_id      # Argument: AMI ID
  instance_type = var.instance_type  # Argument: Instance type
  subnet_id     = var.subnet_id    # Argument: Subnet ID

   iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = var.instance_name
  }
}