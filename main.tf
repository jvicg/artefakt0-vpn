# file: main.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   = "us-east-1" 
  shared_credentials_files = ["${path.module}/key/aws_credentials"]
}

variable "instances_amount" {
  type    = string
  default = "3"   # Amount of instances to be deployed
}

data "aws_vpc" "default" {
  default = true  # Default VPC CIDR block
}

# Instances deployment
resource "aws_instance" "main" {
  ami           = "ami-0cd59ecaf368e5ccf"  # Ubuntu 20.04
  instance_type = "t3.small"               # 2vCPU | 2GiB Mem
  count         = var.instances_amount
  key_name      = aws_key_pair.provisioner.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_k8s.id]
  associate_public_ip_address = true

  tags = {  # The first instance to be deployed will be the k8s master
    Name = "${count.index == 0 ? "k8s_master" : "k8s_slave_${count.index - 1}"}"
  }
}

# Create SSH key pair for the provisioner (Ansible)
resource "aws_key_pair" "provisioner" {
  key_name   = "provisioner-key"
  public_key = file("${path.module}/key/provisioner.pub")
}

# Security Group (definition of firewall rules)
resource "aws_security_group" "allow_ssh_k8s" {
  name        = "allow_ssh_k8s"
  description = "Allow SSH and k8s inbound traffic and all outbound traffic"
  # vpc_id      = aws_vpc.k8s_vpc.id

  # Inbound rules
  ingress {  # ssh
    cidr_blocks       = ["0.0.0.0/0"]  # range of allowed IPs
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
  }

  ingress { # icmp (for testing porpuses) 
    cidr_blocks       = ["0.0.0.0/0"]
    protocol          = "icmp"
    from_port         = -1  # -1 stands for all ports
    to_port           = -1
  }

  ingress {  # kubectl
    cidr_blocks       = [data.aws_vpc.default.cidr_block]  # Only allow communicatio between members of the default VPC
    protocol          = "tcp"
    from_port         = 6443
    to_port           = 6443
  }

  # Allow all the outgoing traffic
  egress {
    cidr_blocks       = ["0.0.0.0/0"]
    protocol          = "-1" 
    from_port         = 0
    to_port           = 0
  }
}

# Files generation
resource "local_file" "inventory" {  # Ansible's inventory
  content = templatefile("${path.module}/template/ansible_inventory.tftpl", {
    instances = aws_instance.main,
  })
  filename = "${path.module}/build/provisioner/inventory"
}

resource "local_file" "hosts" {  # /etc/hosts (for the nodes)
  content = templatefile("${path.module}/template/k8s_hosts.tftpl", {
    instances = aws_instance.main
  })
  filename = "${path.module}/build/provisioner/hosts"
}
