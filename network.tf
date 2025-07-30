module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "connect-vpc"
  cidr = "10.0.0.0/16"

  azs                  = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets      = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  public_subnets       = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  private_subnet_names = ["connect-priv-a", "connect-priv-b", "connect-priv-c"]
  public_subnet_names  = ["connect-pub-a", "connect-pub-b", "connect-pub-c"]

  create_igw           = true
  enable_dns_hostnames = true

  vpc_tags = {
    Name = "connect-vpc"
  }
  igw_tags = {
    Name = "connect-igw"
  }
  tags = {
    project_name = var.project_name
  }
}
