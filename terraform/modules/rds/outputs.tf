output "endpoints" {
  value = { for name, db in aws_db_instance.this : name => db.address }
}
output "usernames" {
  value     = { for name, db in aws_db_instance.this : name => db.username }
  sensitive = true
}
output "passwords" {
  value     = { for name, pwd in random_password.db : name => pwd.result }
  sensitive = true
}
