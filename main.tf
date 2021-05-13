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
  region       = "eu-west-1"
  az_1         = "${local.region}a" # availability zone eu-west-1c
  az_2         = "${local.region}c" # availability zone eu-west-1c
  app_template = "lt-0eb371797eb762caf" # launch template for app instances
  app_image    = "ami-0eace738484749e4b" # app instance image
  db_image     = "ami-04c1689efbc903e17" # database instance id
  type         = "t2.micro" # defines the type of instance
  key          = "eng84devops" # defines the ssh key to be used
  key_path     = "~/.ssh/eng84devops.pem"
  # task_vpc   = "vpc-07e47e9d90d2076da" # vpc ID for the task
}


# ----- DEFINE PROVIDER -----
provider "aws" { # provider is a keyword to define the cloud provider
  region = local.region # define the availability region for the instance
}


# ----- CREATE RESOURCES -----


# ----- VPC RESOURCES -----

# block of code to create a VPC
resource "aws_vpc" "sav_tf_vpc" {
  cidr_block       = "10.0.0.0/16"
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
    Name = "eng84_sav_tf_gateway"
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
    Name = "eng84_sav_tf_public_RT"
  }
}

# ----- CREATE SUBNETS -----
# block of code to create a public subnet in region eu-west-1a
resource "aws_subnet" "sav_public_net_a" {
  vpc_id                  = aws_vpc.sav_tf_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone       = local.az_1
  # route_table = aws_route_table.sav_tf_route.id

  tags = {
    Name = "eng84_sav_tf_public_net_a"
  }
}

# block of code to create a public subnet in region eu-west-1c
resource "aws_subnet" "sav_public_net_b" {
  vpc_id                  = aws_vpc.sav_tf_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "true" # makes it a public subnet
  availability_zone       = local.az_2
  # route_table = aws_route_table.sav_tf_route.id

  tags = {
    Name = "eng84_sav_tf_public_net_b"
  }
}

# block of code to create a private subnet
resource "aws_subnet" "sav_private_net" {
  vpc_id                  = aws_vpc.sav_tf_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false" # makes it a private subnet

  tags = {
    Name = "eng84_sav_tf_private_net"
  }
}

# ----- SUBNET RULES -----
# route table association to public subnet a
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.sav_public_net_a.id
  route_table_id = aws_route_table.sav_tf_route.id
}

# route table association to public subnet b
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.sav_public_net_b.id
  route_table_id = aws_route_table.sav_tf_route.id
}

# route table association to public subnet ---- TEMP ----
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.sav_private_net.id
  route_table_id = aws_route_table.sav_tf_route.id # associated with public route table for debug
}

# ----- SECURITY GROUPS -----
# create a public security group
resource "aws_security_group" "sav_public_SG_1" {
  name        = "sav_public_SG_1"
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
    Name = "eng84_sav_tf_public_SG_1"
  }
}

# create security group rule "http"
resource "aws_security_group_rule" "public_http_1" {
  description       = "allows access from the internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_1.id
}

# create security group rule "ssh"
resource "aws_security_group_rule" "public_shh_1" {
  description       = "allows access from my IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["165.120.9.26/32"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_1.id
}

# create security group rule "self"
resource "aws_security_group_rule" "public_self_1" {
  description       = "allows access from itself"
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
  cidr_blocks       = ["10.0.1.0/24"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_1.id
}

# create a public security group 2
resource "aws_security_group" "sav_public_SG_2" {
  name        = "sav_public_SG_2"
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
    Name = "eng84_sav_tf_public_SG_2"
  }
}

# create security group rule "http"
resource "aws_security_group_rule" "public_http_2" {
  description       = "allows access from the internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_2.id
}

# create security group rule "ssh"
resource "aws_security_group_rule" "public_shh_2" {
  description       = "allows access from my IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["165.120.9.26/32"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_2.id
}

# create security group rule "self"
resource "aws_security_group_rule" "public_self_2" {
  description       = "allows access from itself"
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
  cidr_blocks       = ["10.0.1.0/24"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sav_public_SG_2.id
}



# # create a private security group
# resource "aws_security_group" "sav_private_SG" {
#   name        = "sav_private_SG"
#   description = "allows inbound traffic"
#   vpc_id      = aws_vpc.sav_tf_vpc.id

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "eng84_sav_tf_private_SG"
#   }
# }

# # create security group rule "ssh"
# resource "aws_security_group_rule" "private_shh" {
#   description       = "allows access from my IP"
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["165.120.9.26/32"]
#   ipv6_cidr_blocks  = ["::/0"]
#   security_group_id = aws_security_group.sav_private_SG.id
# }

# # create security group rule "self"
# resource "aws_security_group_rule" "private_self" {
#   description       = "allows access from itself"
#   type              = "ingress"
#   from_port         = "-1"
#   to_port           = "-1"
#   protocol          = "-1"
#   cidr_blocks       = ["10.0.1.0/24"]
#   ipv6_cidr_blocks  = ["::/0"]
#   security_group_id = aws_security_group.sav_private_SG.id
# }


# ----- AUTO SCALER -----
# create launch configuration
resource "aws_launch_template" "sav_launch_app" {
  name   = "eng84_sav_tf_tpl"
  image_id      = local.app_image
  ebs_optimized = false
  instance_type = "t2.micro"
  key_name      = "eng84devops"
#  security_groups = [aws_security_group.sav_public_SG_1.id]
#  associate_public_ip_address = true

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.sav_public_SG_1.id]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "sav_auto_scale" {
  # availability_zones   = [local.az_1, local.az_2]
  vpc_zone_identifier = [aws_subnet.sav_public_net_a.id, aws_subnet.sav_public_net_b.id]
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  health_check_type    = "EC2"
  target_group_arns    = ["${aws_lb_target_group.sav_target_1.arn}"]
  depends_on           = [aws_launch_template.sav_launch_app, aws_lb_listener.sav_listen_1]

  launch_template {
    id      = aws_launch_template.sav_launch_app.id
    version = "$Latest"
  }

  # launch_template {
  #   id      = local.app_template
  #   version = "$Latest"
  # }

  lifecycle {
    ignore_changes = [target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = "eng84_sav_tf_app"
    propagate_at_launch = true
  }
}

# ----- LOAD BALANCER -----
# create target group 1
resource "aws_lb_target_group" "sav_target_1" {
  name        = "eng84-sav-tf-TG-1"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.sav_tf_vpc.id

  tags = {
    Name = "eng84_sav_TG_1"
  }
}

# create listener
resource "aws_lb_listener" "sav_listen_1" {
  load_balancer_arn = aws_lb.sav_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sav_target_1.arn
  }
}

# # create target group 2
# resource "aws_lb_target_group" "sav_target_2" {
#   name        = "eng84-sav-tf-TG-2"
#   port        = 80
#   protocol    = "HTTP"
#   target_type = "ip"
#   vpc_id      = aws_vpc.main.id
# }

# create load balancer
resource "aws_lb" "sav_lb" {
  name               = "eng84-sav-tf-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sav_public_SG_1.id, aws_security_group.sav_public_SG_2.id]
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

#   vpc_security_group_ids = [aws_security_group.sav_public_SG_1.id]

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

#   vpc_security_group_ids = [aws_security_group.sav_public_SG_1.id]

#   tags = {
#       Name = "eng84_sav_tf_db"
#   }
# }
