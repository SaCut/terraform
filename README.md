# Terraform
- Terraform is an orchestration tool for building, changing, and versioning infrastructure.
- It allows treating infosrtucture (servers, VPCs, subnets) as pieces of code on a file.
- Terraform uses json-style syntax for its input files and a specific file extension, `.tf`.
- Compared to Ansible, Terraform is of much easier use.

#### Terraform diagram
![img](https://imgur.com/SgBFr0Z.png)

#### Credentials
- Create two environment variables, one called `AWS_ACCESS_KEY_ID`, another called `AWS_SECRET_ACCESS_KEY`, and set them to the AWS access credentials
- edit `nano main.tf`

#### useful commands
- `terraform init` initialises the terraform project
- `terraform plan` checks the syntax of the code and that the project has no running problems
- `terraform appy` actually creates the objects specified in the present-path file
- `terraform destroy` destroys all the objects specified in the present-path file

#### Creating objects - example of a file
- A cloud service provider can be choosen with
```tf
provider "aws" {
  # define the availability region for the instance
  region = "eu-west-1"
}
```
- Setting up an instance:
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