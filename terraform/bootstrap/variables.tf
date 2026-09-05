variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "state_bucket_name" {
  description = "Nome globalmente único do bucket de estado."
  type        = string
}

