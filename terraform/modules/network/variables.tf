variable "name" { type = string }
variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}
variable "enable_nat_gateway" {
  type    = bool
  default = true
}
