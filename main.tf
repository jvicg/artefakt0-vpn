# file: main.tf

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

# instances
resource "aws_instance" "deploy" {
  ami           = "ami-080e1f13689e07408"  # ubuntu 22.04
  # count         = "3"
  instance_type = "t3.small"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_k8s.id]
}

# create a ssh key pair so ansible can access the instances
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("./ssh/artefakt0.pub")
}

# security group (definition of firewall rules)
resource "aws_security_group" "allow_ssh_k8s" {
  name        = "allow_ssh_k8s"
  description = "Allow SSH and K8s inbound traffic and all outbound traffic"

  ingress {  # allow SSH incoming traffic
    cidr_blocks       = ["0.0.0.0/0"]
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
  }

  ingress {  # allow connection between k8s master with the workers)
    cidr_blocks       = ["172.31.0.0/16"]
    protocol          = "tcp"
    from_port         = 6443
    to_port           = 6443
  }

  # allow all the outgoing traffic
  egress {
    cidr_blocks       = ["0.0.0.0/0"]
    protocol          = "tcp" 
    from_port         = 0
    to_port           = 0
  }
}

# outputs management
output "test" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.test.public_dns
}
