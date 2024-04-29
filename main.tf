# main.tf
# File responsible for the deployment of the AWS Instances

# Providers installation
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"  # Not update further than 5.x
    }
  }
}

# Set AWS region and credentials
provider "aws" {
  region                   = local.vars.region
  shared_credentials_files = [ "${path.module}/aws_credentials" ]
}

# Variables
locals {
  vars = {
    ami              = "ami-0cd59ecaf368e5ccf"  # Ubuntu 20.04
    user             = "provisioner"            # User responsible of the provision
    instance_type    = "t3.small"               # 2vCPU | 2GiB Mem
    instances_amount = "3"                      # Number of instances to be deployed
    region           = "us-east-1"              

    generated_files  = {
      inventory     = "ansible_inventory",      # Name of the file = Name of the template
      common_hosts  = "k8s_hosts"
    }
  }

  dirs = {
    templates = "${path.module}/templates"
  }
}

# Default VPC CIDR block (e.g: 172.31.10.0/16)
data "aws_vpc" "default" {
  default = true  
}

# Instances deployment
resource "aws_instance" "main" {
  ami           = local.vars.ami
  count         = local.vars.instances_amount
  instance_type = local.vars.instance_type
  key_name      = aws_key_pair.provisioner.key_name
  vpc_security_group_ids = [aws_security_group.allow_k8s_ssh.id]
  associate_public_ip_address = true

  tags = {  # The first instance to be deployed will be the master node
    Name = "${count.index == 0 ? "k8scp" : "k8sworker${count.index - 1}"}"
  }

  user_data = templatefile("${local.dirs.templates}/user_data.sh.tftpl", {
    username   = local.vars.user,
    public_key = aws_key_pair.provisioner.public_key
  })

  depends_on = [
    aws_key_pair.provisioner,
    aws_security_group.allow_k8s_ssh
  ]
}

# Create SSH key pair for the provisioner (Ansible)
resource "aws_key_pair" "provisioner" {
  key_name   = "provisioner-key"
  public_key = file("${path.module}/key/provisioner.key.pub")
}

# Security Group (definition of firewall rules)
resource "aws_security_group" "allow_k8s_ssh" {
  name        = "allow_k8s_ssh"
  description = "Allow port 22 (SSH) and port 6443 (k8s) inbound traffic and all outbound traffic"

  # Inbound rules
  ingress {  # ssh
    cidr_blocks       = [ "0.0.0.0/0" ]  # Range of allowed IPs
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
  }

  ingress { # icmp (for testing purposes) 
    cidr_blocks       = [ "0.0.0.0/0" ]
    protocol          = "icmp"
    from_port         = -1  # -1 stands for all ports
    to_port           = -1
  }

  ingress {  # kubectl
    cidr_blocks       = [ data.aws_vpc.default.cidr_block ]  # Allow communication between k8s master and workers
    protocol          = "tcp"
    from_port         = 6443
    to_port           = 6443
  }

  # Allow all the outgoing traffic
  egress {
    cidr_blocks       = [ "0.0.0.0/0" ]
    protocol          = "-1" 
    from_port         = 0
    to_port           = 0
  }
}

# Create an S3 bucket to store the status of terraform (.tfstate)
resource "aws_s3_bucket" "terraform-gen-files" {
  bucket        = "terraform-gen-files"  
  force_destroy = true

  tags = {
    Name = "provisioner-bucket"
  }
}

# Files generation
resource "local_file" "dynamic_addresses" {  # inventory & hosts
  for_each = local.vars.generated_files
  content  = templatefile("${local.dirs.templates}/${each.value}.tftpl", {
    instances = aws_instance.main
  })
  filename = "${path.module}/${each.key}.s3"  # The files will be named with '.s3' format
  depends_on = [ aws_instance.main ]
}

resource "local_file" "ansible_cfg" {   # ansible.cfg
  content  = templatefile("${local.dirs.templates}/ansible_cfg.tftpl", {
    username = local.vars.user
  })
  filename = "${path.module}/ansible.cfg.s3"  
  depends_on = [ aws_instance.main ]
}
