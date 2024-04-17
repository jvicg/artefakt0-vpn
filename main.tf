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
  ami           = "ami-0cd59ecaf368e5ccf"  # ubuntu 20.04
  count         = "3"
  instance_type = "t3.small"
  key_name      = aws_key_pair.provisioner.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_k8s.id]
  subnet_id     = aws_subnet.k8s_subnet.id

  # network_interface {
  #   network_interface_id = aws_network_interface.eth0.id
  #   device_index         = 0
  # }

  tags = {
    Name = "${count.index == 0 ? "k8s_master" : "k8s_slave_${count.index - 1}"}"
  }
}

# create a ssh key pair so ansible can access the instances
resource "aws_key_pair" "provisioner" {
  key_name   = "provisioner-key"
  public_key = file("${path.module}/key/provisioner.pub")
}

# create a subnet to make sure that instances are always running in the same network
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_subnet" "k8s_subnet" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "k8s-subnet"
  }
}

# security group (definition of firewall rules)
resource "aws_security_group" "allow_ssh_k8s" {
  name        = "allow_ssh_k8s"
  description = "Allow SSH and K8s inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.k8s_vpc.id

  # allow SSH incoming traffic
  ingress {  
    cidr_blocks       = ["0.0.0.0/0"]  # range of allowed IPs
    protocol          = "tcp"
    from_port         = 22
    to_port           = 22
  }

  # allow ICMP protocol (for testing porpuses)
  ingress {  
    cidr_blocks       = ["0.0.0.0/0"]
    protocol          = "icmp"
    from_port         = -1  # -1 stands for all ports
    to_port           = -1
  }

  # allow connection between k8s master with the workers)
  ingress {  
    cidr_blocks       = ["172.16.10.0/24"]
    protocol          = "tcp"
    from_port         = 6443
    to_port           = 6443
  }

  # allow all the outgoing traffic
  egress {
    # cidr_blocks       = ["0.0.0.0/0"]
    protocol          = "-1" 
    from_port         = 0
    to_port           = 0
  }
}

# generate a file with the public DNS of the instances
resource "local_file" "inventory" {
  content = templatefile("${path.module}/template/ansible_inventory.tfpl", {
    instances = aws_instance.main
  })
  filename = "${path.module}/build/provisioner/inventory"
}

# generate a file with the private IPs of the instances
resource "local_file" "hosts" {
  content = templatefile("${path.module}/template/k8s_hosts.tfpl", {
    instances = aws_instance.main
  })
  filename = "${path.module}/build/provisioner/hosts"
}