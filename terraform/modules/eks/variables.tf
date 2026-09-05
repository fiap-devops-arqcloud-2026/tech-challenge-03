variable "name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "lab_role_arn" {
  type      = string
  sensitive = true
}
variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
