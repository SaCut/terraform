# let's initialise terraform
# Providers?
# AWS

# This code will eventually launch an EC2 instance for us


# ----- VARIABLES -----

# variable "subnets_cidr" {
#   type = list
#   default = ["10.0.1.0/24", "10.0.2.0/24"]
# }

locals {
  az = "eu-west-1"
  app_image = "ami-040b1f6b252d7350d" # app instance image
  db_image = "ami-04408febde5e989a1" # database instance id
  type = "t2.micro" # defines the type of instance
  key = "eng84devops" # defines the ssh key to be used
  # task_vpc = "vpc-07e47e9d90d2076da" # vpc ID for the task
}


# ----- DEFINE PROVIDER -----
provider "aws" { # provider is a keyword to define the cloud provider
  region = local.az # define the availability region for the instance
}


# ----- CREATE RESOURCES -----

# ----- VPC RESOURCES -----

# block of code to create a VPC
resource "aws_vpc" "sav_tf_vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "eng84_saverio_tf_vpc"
  }
}

# create internet gateway
resource "aws_internet_gateway" "sav_tf_gate" {
  vpc_id = aws_vpc.sav_tf_vpc.id

  tags = {
    name = "eng84_sav_tf_gateway"
  }
}

# create route table
resource "aws_route_table" "sav_tf_route" {
  vpc_id = aws_vpc.sav_tf_vpc.id
  # subnet_id = aws_subnet.sav_public_net.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sav_tf_gate.id
  }

  tags = {
    name = "eng84_sav_tf_public_RT"
  }
}

# block of code to create a public subnet
resource "aws_subnet" "sav_public_net" {
  vpc_id = aws_vpc.sav_tf_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone = "${local.az}c"
  # route_table = aws_route_table.sav_tf_route.id

  tags = {
    name = "eng84_sav_tf_public_net"
  }
}

# block of code to create a private subnet
resource "aws_subnet" "sav_private_net" {
  vpc_id = aws_vpc.sav_tf_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = "false" # makes it a private subnet

  tags = {
    name = "eng84_sav_tf_private_net"
  }
}

# route table association to public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.sav_public_net.id
  route_table_id = aws_route_table.sav_tf_route.id
}

# route table association to public subnet ---- TEMP ----
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.sav_private_net.id
  route_table_id = aws_route_table.sav_tf_route.id # associated with public route table for debug
}

# create a public security group
resource "aws_security_group" "sav_public_SG" {
  name        = "sav_public_SG"
    description = "allows inbound traffic"
    vpc_id      = aws_vpc.sav_tf_vpc.id

    # ingress = [
    #   {
    #     description       = "allows access from the internet"
    #     type              = "ingress"
    #     from_port         = 80
    #     to_port           = 80
    #     protocol          = "tcp"
    #     cidr_blocks       = ["0.0.0.0/0"]
    #     ipv6_cidr_blocks  = ["::/0"]
    #     security_group_id = aws_security_group.sav_public_SG.id
    #   },
    #   {
    #     description       = "allows access from my IP"
    #     type              = "ingress"
    #     from_port         = 22
    #     to_port           = 22
    #     protocol          = "tcp"
    #     cidr_blocks       = ["165.120.9.26/32"]
    #     ipv6_cidr_blocks  = ["::/0"]
    #     security_group_id = aws_security_group.sav_public_SG.id
    #   }
    # ]

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
      Name = "eng84_sav_tf_public_SG"
    }
}

# create security group rule "http"
resource "aws_security_group_rule" "http" {
  description       = "allows access from the internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG.id
}

# create security group rule "ssh"
resource "aws_security_group_rule" "shh" {
  description       = "allows access from my IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["165.120.9.26/32"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG.id
}


# ----- EC2 RESOURCES -----

# launching app EC2 instance from AMI
resource "aws_instance" "sav_tf_app" {
  ami = local.app_image # define the source image

  instance_type = local.type # define the type of instance

  key_name = local.key

  private_ip = "10.0.1.100" # set the private ip

  associate_public_ip_address = true # enable public ip on instance

  subnet_id = aws_subnet.sav_public_net.id # set the subnet

  vpc_security_group_ids = [aws_security_group.sav_public_SG.id]

  tags = {
      Name = "eng84_sav_tf_app"
  }
}

# launching db EC2 instance from AMI
resource "aws_instance" "sav_tf_db" {
  ami = local.db_image # define the source image

  instance_type = local.type

  key_name = local.key

  private_ip = "10.0.2.100" # set the private ip

  associate_public_ip_address = false # no public ip

  subnet_id = aws_subnet.sav_private_net.id

  vpc_security_group_ids = [aws_security_group.sav_public_SG.id]

  tags = {
      Name = "eng84_sav_tf_app"
  }
}
