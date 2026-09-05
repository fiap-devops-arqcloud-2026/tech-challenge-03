variable "name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "subnet_ids" { type = list(string) }
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "database_names" {
  type    = set(string)
  default = ["auth", "flags", "targeting"]
}
