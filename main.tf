# let's initialise terraform
# Providers?
# AWS

# This code will eventually launch an EC2 instance for us

# provider is a keyword to define the cloud provider

provider "aws" {
  # define the availability region for the instance
  region = "eu-west-1"
}

# launching an EC2 instance from an AMI
# resource allows us to add aws

resource "aws_instance" "app_instance" {
  #add the AMI between double quotes
  ami = "ami-040b1f6b252d7350d"

  # let's also define the type of instance
  instance_type = "t2.micro"

  # enable piblic ip on instance
  associate_public_ip_address = true

  # also add tags
  tags = {
      Name = "eng84_saverio_tf_node_app"
  }
}