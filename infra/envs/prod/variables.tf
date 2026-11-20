variable "region" { type = string }
variable "name" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "ecs_cpu" { type = string }
variable "ecs_memory" { type = string }
variable "ecs_desired_count" { type = number }
variable "container_image" { type = string }
variable "rds_instance_class" { type = string }
variable "rds_storage_gb" { type = number }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "backup_retention" { type = number }
variable "deletion_protection" { type = bool }
