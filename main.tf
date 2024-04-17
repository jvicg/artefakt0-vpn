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

# instances
resource "aws_instance" "main" {
  # ami           = "ami-080e1f13689e07408"  # ubuntu 22.04
  ami           = "ami-0cd59ecaf368e5ccf"  # ubuntu 20.04
  count         = "3"
  instance_type = "t3.small"
  key_name      = aws_key_pair.provisioner.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_k8s.id]

  tags = {
    Name = "${count.index == 0 ? "k8s_master" : "k8s_slave_${count.index - 1}"}"
  }
}

# create a ssh key pair so ansible can access the instances
resource "aws_key_pair" "provisioner" {
  key_name   = "provisioner-key"
  public_key = file("${path.module}/key/provisioner.pub")
}

# security group (definition of firewall rules)
resource "aws_security_group" "allow_ssh_k8s" {
  name        = "allow_ssh_k8s"
  description = "Allow SSH and K8s inbound traffic and all outbound traffic"

  # allow SSH incoming traffic
  ingress {  
    cidr_blocks       = ["0.0.0.0/0"]  # range of allowed IPs
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
  }

  # allow ICMP protocol (for testing porpuses)
  ingress {  
    protocol          = "icmp"
    from_port         = -1  # -1 stands for all ports
    to_port           = -1
  }

  # allow connection between k8s master with the workers)
  ingress {  
    cidr_blocks       = ["172.31.0.0/16"]
    protocol          = "tcp"
    from_port         = 6443
    to_port           = 6443
  }

  # allow all the outgoing traffic
  egress {
    cidr_blocks       = ["0.0.0.0/0"]
    protocol          = "-1" 
    from_port         = 0
    to_port           = 0
  }
}

# generate a file with the public DNS of the instances
resource "local_file" "inventory" {
  content = templatefile("${path.module}/ansible_inventory.tfpl", {
    instances = aws_instance.main
  })
  filename = "${path.module}/build/provisioner/inventory"
}

# generate a file with the private IPs of the instances
resource "local_file" "hosts" {
  content = templatefile("${path.module}/k8s_hosts.tfpl", {
    instances = aws_instance.main
  })
  filename = "${path.module}/build/provisioner/hosts"
}