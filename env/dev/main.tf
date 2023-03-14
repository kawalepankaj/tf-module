provider "aws" {
  profile = "manager"
  region  = "us-east-1"
}

module "vpc" {
  source             = "../../modules/vpc"
  env                = "dev"
  appname            = "student"
  vpc_cidr_block     = "192.168.0.0/16"
  public_cidr_block  = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  private_cidr_block = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  tags = {
    Owner = "dev-team"
  }
}


module "load-balancer" {
  source = "../../modules/loadbalancer"
  env = "dev"
  appname = "mylb"
  internal = "false"
  type = "application"
  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.vpc.security_groups]
  vpc_id          = module.vpc.vpc_id
  tags={
    Owner = "dev-team"
    type = "internet-facing"
  }
}
