# _provider.tf
provider "aws" {
  alias = "ireland"
  region = "eu-west-1" 
}

provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}