# Custom DB Parameter Group
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.app_name}-postgres-ssl-disabled"
  family = "postgres17"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

# RDS Instance
resource "aws_db_instance" "postgres" {
  allocated_storage       = 20 # Free tier includes 20GB
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "17.2"
  instance_class          = "db.t3.micro" # Free tier eligible
  identifier              = "${var.app_name}-db"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = aws_db_parameter_group.postgres.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  backup_retention_period = 0 # Disable automated backups to stay within free tier
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  publicly_accessible     = false
  storage_encrypted       = false                # Disable encryption to stay within free tier
  monitoring_interval     = 0                    # Disable enhanced monitoring to stay within free tier
  multi_az                = false                # Disable multi-AZ to stay within free tier
  availability_zone       = "${var.aws_region}a" # Specify AZ to ensure consistent placement
}
