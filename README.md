# terraform

### Resources
#### EC2 instance AMI IDs:
- Webapp AMI ID: ami-040b1f6b252d7350d
- Database AMI ID: ami-04408febde5e989a1

#### Credentials
- Create two environment variables, one called `AWS_ACCESS_KEY_ID`, another called `AWS_SECRET_ACCESS_KEY`, and set them to the AWS access credentials
- edit `nano main.tf`
- choose provider with
```tf
provider "aws" {
  # define the availability region for the instance
  region = "eu-west-1"
}
```
- Set up instance:
```tf
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
```

#### useful commands
- `terraform init` initialises the terraform project
- `terraform plan` checks the syntax of the code and that the project has no running problems
- `terraform appy`
- `terraform destroy`
