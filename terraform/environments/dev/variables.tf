variable "aws_region" {
  type    = string
  default = "us-east-2"
}
variable "project_name" {
  type    = string
  default = "togglemaster"
}
variable "environment" {
  type    = string
  default = "dev"
}

variable "lab_role_arn" {
  description = "ARN da LabRole existente no AWS Academy."
  type        = string
  sensitive   = true
}

variable "enable_nat_gateway" {
  description = "NAT Gateway cobra por hora. Destrua o ambiente após a demonstração."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
