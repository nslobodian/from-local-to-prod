variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-03250b0e01c28d196" # Ubuntu Server 24.04 LTS 64bit
}

variable "repository_url" {
  description = "URL of the Git repository to clone"
  type        = string
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "nestjs_app_db"
}

variable "db_username" {
  description = "Master username for RDS instance"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for RDS instance"
  type        = string
  sensitive   = true
}

variable "db_migration_username" {
  description = "Username for database migrations"
  type        = string
  default     = "migration_user"
}

variable "db_migration_password" {
  description = "Password for database migrations"
  type        = string
  sensitive   = true
}

variable "db_app_username" {
  description = "Username for application database access"
  type        = string
  default     = "app_user"
}

variable "db_app_password" {
  description = "Password for application database access"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "app"
}

variable "ssh_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/aws_key.pub"
} 