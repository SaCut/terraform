variable "region" {
  default = "eu-west-1"
}

variable "az" {
  default = "eu-west-1c"
}

variable "app_image" {
  default = "ami-0eace738484749e4b" # updated app AMI with nodejs service at launch
}

variable "db_image" {
  default = "ami-04408febde5e989a1" # updated db AMI with seeded mongodb
}

variable "type" {
  default = "t2.micro"
}

variable "key" {
  default = "eng84devops"
}