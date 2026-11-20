terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" {
  region = var.region

  skip_credentials_validation = true
  skip_metadata_api_check    = true
  skip_requesting_account_id = true
}
module "network" {
  source   = "../../modules/network"
  name     = var.name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}
module "ecs" {
  source            = "../../modules/ecs"
  name              = var.name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  app_subnet_ids    = module.network.app_subnet_ids
  alb_sg_id         = module.network.alb_sg_id
  ecs_sg_id         = module.network.ecs_sg_id
  cpu               = var.ecs_cpu
  memory            = var.ecs_memory
  desired_count     = var.ecs_desired_count
  image             = var.container_image
}
module "rds" {
  source              = "../../modules/rds"
  name                = var.name
  db_subnet_ids       = module.network.db_subnet_ids
  rds_sg_id           = module.network.rds_sg_id
  instance_class      = var.rds_instance_class
  storage_gb          = var.rds_storage_gb
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  backup_retention    = var.backup_retention
  deletion_protection = var.deletion_protection
}
