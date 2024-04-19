# file: main.tf

# Providers installation
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"  # Not update further than 5.x
    }
  }
}

# Variables
locals {
  vars = {
    ami              = "ami-0cd59ecaf368e5ccf"  # Ubuntu 20.04
    instance_type    = "t3.small"               # 2vCPU | 2GiB Mem
    # instance_type    = "t3.medium"            # 2vCPU | 4GiB Mem
    instances_amount = "3"                      # Number of instances to be deployed
    region           = "us-east-1"              
  }
}

# Default VPC CIDR block (e.g: 172.31.10.0/16)
data "aws_vpc" "default" {
  default = true  
}

# Set AWS region and credentials
provider "aws" {
  region                   = local.vars.region
  shared_credentials_files = ["${path.module}/key/aws_credentials"]
}

# Instances deployment
resource "aws_instance" "main" {
  ami           = local.vars.ami
  count         = local.vars.instances_amount
  instance_type = local.vars.instance_type
  key_name      = aws_key_pair.provisioner.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_k8s.id]
  associate_public_ip_address = true

  tags = {  # The first instance to be deployed will be the master node
    Name = "${count.index == 0 ? "k8s_master" : "k8s_slave_${count.index - 1}"}"
  }

  depends_on = [
    aws_key_pair.provisioner,
    aws_security_group.allow_ssh_k8s
  ]
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

  # Inbound rules
  ingress {  # ssh
    cidr_blocks       = ["0.0.0.0/0"]  # Range of allowed IPs
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
    cidr_blocks       = [data.aws_vpc.default.cidr_block]  # Allow communication between k8s master and slaves
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
