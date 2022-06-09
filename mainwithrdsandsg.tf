provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

locals {
  name   = "complete-mysql"
  region = "us-east-1"
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Owner       = "cloud_user"
    Environment = "dev"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Complete MySQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

module "db_default" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-default"

  create_db_option_group    = false
  create_db_parameter_group = false

  engine               = "mysql"
  engine_version       = "8.0.27"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t4g.medium"

  allocated_storage = 20

  db_name  = "completeMysql"
  username = "complete_mysql"
  port     = 3306

  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 0

  tags = local.tags
}
