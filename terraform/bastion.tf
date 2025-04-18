# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name        = "${var.app_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-bastion-sg"
  }
}

# Update RDS Security Group to allow access from bastion
resource "aws_security_group_rule" "rds_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.bastion.id
}

# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type              = "t2.micro"  # Free tier eligible
  subnet_id                  = aws_subnet.public.id
  vpc_security_group_ids     = [aws_security_group.bastion.id]
  key_name                   = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Force instance recreation when user_data changes
  user_data_replace_on_change = true

  # Wait for RDS to be created before creating the bastion
  depends_on = [aws_db_instance.postgres]

  user_data = <<-EOF
              #!/bin/bash
              # Install PostgreSQL client
              sudo apt-get update
              sudo apt-get install -y postgresql-client

              # Create database setup script
              cat > /home/ubuntu/setup_db_users.sh << 'EOS'
              #!/bin/bash
              set -e

              # Wait for RDS to be ready
              while ! nc -z ${aws_db_instance.postgres.endpoint} 5432; do
                sleep 1
              done

              # Create users and set permissions
              PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres.endpoint} -U ${var.db_username} -d ${var.db_name} << 'SQL'
              -- Create migration user
              CREATE USER ${var.db_migration_username} WITH PASSWORD '${var.db_migration_password}';
              GRANT ALL PRIVILEGES ON DATABASE ${var.db_name} TO ${var.db_migration_username};
              GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${var.db_migration_username};
              GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${var.db_migration_username};
              ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${var.db_migration_username};
              ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${var.db_migration_username};

              -- Create app user
              CREATE USER ${var.db_app_username} WITH PASSWORD '${var.db_app_password}';
              GRANT CONNECT ON DATABASE ${var.db_name} TO ${var.db_app_username};
              GRANT USAGE ON SCHEMA public TO ${var.db_app_username};
              GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${var.db_app_username};
              GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${var.db_app_username};
              ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${var.db_app_username};
              ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO ${var.db_app_username};
              SQL
              EOS

              # Make script executable
              chmod +x /home/ubuntu/setup_db_users.sh

              # Run the script
              /home/ubuntu/setup_db_users.sh
              EOF

  tags = {
    Name = "${var.app_name}-bastion"
  }
}

# Output bastion host public IP
output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
} 