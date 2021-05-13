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
  region = "eu-west-1"
  az_1 = "${local.region}a" # availability zone eu-west-1c
  az_2 = "${local.region}c" # availability zone eu-west-1c
  app_template = "lt-0eb371797eb762caf" # launch template for app instances
  app_image = "ami-0eace738484749e4b" # app instance image
  db_image = "ami-04c1689efbc903e17" # database instance id
  type = "t2.micro" # defines the type of instance
  key = "eng84devops" # defines the ssh key to be used
  key_path = "~/.ssh/eng84devops.pem"
  # task_vpc = "vpc-07e47e9d90d2076da" # vpc ID for the task
}


# ----- DEFINE PROVIDER -----
provider "aws" { # provider is a keyword to define the cloud provider
  region = local.region # define the availability region for the instance
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

# ----- ROUTE TABLE -----
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
  # subnet_id = aws_subnet.sav_public_net_a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sav_tf_gate.id
  }

  tags = {
    name = "eng84_sav_tf_public_RT"
  }
}

# ----- CREATE SUBNETS -----
# block of code to create a public subnet in region eu-west-1a
resource "aws_subnet" "sav_public_net_a" {
  vpc_id = aws_vpc.sav_tf_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone = local.az_1
  # route_table = aws_route_table.sav_tf_route.id

  tags = {
    name = "eng84_sav_tf_public_net_1a"
  }
}

# block of code to create a public subnet in region eu-west-1c
resource "aws_subnet" "sav_public_net_b" {
  vpc_id = aws_vpc.sav_tf_vpc.id
  cidr_block = "10.0.4.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone = local.az_2
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

# ----- SUBNET RULES -----
# route table association to public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.sav_public_net_a.id
  route_table_id = aws_route_table.sav_tf_route.id
}

# route table association to public subnet ---- TEMP ----
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.sav_private_net.id
  route_table_id = aws_route_table.sav_tf_route.id # associated with public route table for debug
}

# ----- SECURITY GROUPS -----
# create a public security group
resource "aws_security_group" "sav_public_SG" {
  name        = "sav_public_SG"
    description = "allows inbound traffic"
    vpc_id      = aws_vpc.sav_tf_vpc.id

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
resource "aws_security_group_rule" "public_http" {
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
resource "aws_security_group_rule" "public_shh" {
  description       = "allows access from my IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["165.120.9.26/32"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG.id
}

# create security group rule "self"
resource "aws_security_group_rule" "public_self" {
  description       = "allows access from itself"
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
  cidr_blocks       = ["10.0.1.0/24"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG.id
}


# create a private security group
resource "aws_security_group" "sav_private_SG" {
  name        = "sav_private_SG"
    description = "allows inbound traffic"
    vpc_id      = aws_vpc.sav_tf_vpc.id

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
      Name = "eng84_sav_tf_private_SG"
    }
}

# create security group rule "ssh"
resource "aws_security_group_rule" "private_shh" {
  description       = "allows access from my IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["165.120.9.26/32"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_private_SG.id
}

# create security group rule "self"
resource "aws_security_group_rule" "private_self" {
  description       = "allows access from itself"
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
  cidr_blocks       = ["10.0.1.0/24"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_private_SG.id
}


# ----- AUTO SCALER -----
# Auto Scaling Group
resource "aws_autoscaling_group" "sav_auto_scale" {
  availability_zones = [local.az_1, local.az_2]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 1

  launch_template {
    id      = local.app_template
    version = "$Latest"
  }
}

# ----- LOAD BALANCER -----
# create target group


# create load balancer
resource "aws_lb" "sav_lb" {
  name               = "eng84-sav-tf-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sav_public_SG.id, aws_security_group.sav_private_SG.id]
  subnets            = [aws_subnet.sav_public_net_a.id, aws_subnet.sav_public_net_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "eng84_sav_tf_ALB"
  }
}


# # ----- EC2 INSTANCES -----

# # launching app EC2 instance from AMI
# resource "aws_instance" "sav_tf_app" {
#   ami = local.app_image # define the source image

#   instance_type = local.type # define the type of instance

#   key_name = local.key

#   private_ip = "10.0.1.100" # set the private ip

#   associate_public_ip_address = true # enable public ip on instance

#   subnet_id = aws_subnet.sav_public_net_a.id # set the subnet

#   vpc_security_group_ids = [aws_security_group.sav_public_SG.id]

#   # ----- INSTALLING STUFF IN DB INSTANCE FROM APP -----
#   # provisioner "remote-exec" {
#   #   script = "./scripts/app/seed_db.sh"
#   # }

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file(local.key_path)
#     host        = self.public_ip
#   }
#   # ----- END SEEDING -----

#   provisioner "remote-exec" {
#     inline = [
#       "chmod +x ~/init.sh",
#       "~/init.sh",
#     ]
#   }

#   provisioner "file" {
#     source      = "./scripts/app/init.sh"
#     destination = "~/init.sh"
#   }

#   tags = {
#       Name = "eng84_sav_tf_app"
#   }
# }

# # launching db EC2 instance from AMI
# resource "aws_instance" "sav_tf_db" {
#   ami = local.db_image # define the source image

#   instance_type = local.type

#   key_name = local.key

#   private_ip = "10.0.2.100" # set the private ip

#   associate_public_ip_address = true # for ssh

#   subnet_id = aws_subnet.sav_private_net.id

#   vpc_security_group_ids = [aws_security_group.sav_public_SG.id]

#   tags = {
#       Name = "eng84_sav_tf_db"
#   }
# }
