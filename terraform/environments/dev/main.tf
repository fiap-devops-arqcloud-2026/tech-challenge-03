locals {
  name     = "${var.project_name}-${var.environment}"
  services = ["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"]
}

module "network" {
  source             = "../../modules/network"
  name               = local.name
  enable_nat_gateway = var.enable_nat_gateway
}

module "ecr" {
  source        = "../../modules/ecr"
  service_names = toset(local.services)
}

module "sqs" {
  source = "../../modules/sqs"
  name   = local.name
}

module "dynamodb" {
  source     = "../../modules/dynamodb"
  table_name = "ToggleMasterAnalytics"
}

module "rds" {
  source         = "../../modules/rds"
  name           = local.name
  vpc_id         = module.network.vpc_id
  vpc_cidr       = module.network.vpc_cidr
  subnet_ids     = module.network.private_subnet_ids
  instance_class = var.db_instance_class
}

module "elasticache" {
  source     = "../../modules/elasticache"
  name       = local.name
  vpc_id     = module.network.vpc_id
  vpc_cidr   = module.network.vpc_cidr
  subnet_ids = module.network.private_subnet_ids
}

module "eks" {
  source         = "../../modules/eks"
  name           = "${local.name}-cluster"
  subnet_ids     = module.network.private_subnet_ids
  lab_role_arn   = var.lab_role_arn
  instance_types = var.node_instance_types
}

