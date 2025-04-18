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
  allocated_storage       = 20  # Free tier includes 20GB
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "17.2"
  instance_class         = "db.t3.micro"  # Free tier eligible
  identifier             = "${var.app_name}-db"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.postgres.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  backup_retention_period = 0  # Disable automated backups to stay within free tier
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  publicly_accessible    = false
  storage_encrypted      = false  # Disable encryption to stay within free tier
  monitoring_interval    = 0  # Disable enhanced monitoring to stay within free tier
  multi_az              = false  # Disable multi-AZ to stay within free tier
  availability_zone     = "${var.aws_region}a"  # Specify AZ to ensure consistent placement

  # Initial database setup
  provisioner "local-exec" {
    command = <<-EOT
      # Check if psql is installed, if not install it
      if ! command -v psql &> /dev/null; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
          # For Linux, use apt-get without sudo
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -y && apt-get install -y postgresql-client
        elif [[ "$OSTYPE" == "darwin"* ]]; then
          # For macOS, use Homebrew without sudo
          if ! command -v brew &> /dev/null; then
            echo "Homebrew not found. Please install it first: https://brew.sh/"
            exit 1
          fi
          brew install postgresql
        else
          echo "Unsupported OS. Please install postgresql-client manually."
          exit 1
        fi
      fi

      # Test connection first
      echo "Testing database connection..."
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres.endpoint} -U ${var.db_username} -d postgres -c "SELECT 1" || {
        echo "Failed to connect to database"
        exit 1
      }

      echo "Connection successful, proceeding with setup..."
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres.endpoint} -U ${var.db_username} -d postgres << EOF
      -- Create migration user
      CREATE USER ${var.db_migration_username} WITH PASSWORD '${var.db_migration_password}';
      
      -- Create application user
      CREATE USER ${var.db_app_username} WITH PASSWORD '${var.db_app_password}';
      
      -- Create database
      CREATE DATABASE ${var.db_name};
      
      -- Grant migration user privileges
      GRANT ALL PRIVILEGES ON DATABASE ${var.db_name} TO ${var.db_migration_username};
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${var.db_migration_username};
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${var.db_migration_username};
      GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ${var.db_migration_username};
      GRANT CREATE ON SCHEMA public TO ${var.db_migration_username};
      
      -- Grant application user privileges
      GRANT CONNECT ON DATABASE ${var.db_name} TO ${var.db_app_username};
      GRANT USAGE ON SCHEMA public TO ${var.db_app_username};
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${var.db_app_username};
      GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${var.db_app_username};
      GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${var.db_app_username};
      
      -- Set default privileges for future objects
      ALTER DEFAULT PRIVILEGES IN SCHEMA public
      GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${var.db_app_username};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public
      GRANT USAGE, SELECT ON SEQUENCES TO ${var.db_app_username};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public
      GRANT EXECUTE ON FUNCTIONS TO ${var.db_app_username};
      EOF
    EOT
  }
} 