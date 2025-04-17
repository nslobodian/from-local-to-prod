terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "app-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet 1
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "private-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "private-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # Allow all traffic within the VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR block
  }

  tags = {
    Name = "rds-sg"
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"  # Free tier eligible
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Force instance recreation when user_data changes
  user_data_replace_on_change = true

  # Free tier: 30GB of EBS storage
  root_block_device {
    volume_size = 8  # Using 8GB to stay well within free tier
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Create setup script
              cat > /tmp/setup.sh << 'EOS'
              ${templatefile("templates/setup.sh", {
                repository_url = var.repository_url
                db_host       = replace(aws_db_instance.postgres.endpoint, ":5432", "")  # Remove port from endpoint
                db_username   = var.db_username
                db_password   = var.db_password
                db_name       = var.db_name
              })}
              EOS
              
              # Make script executable and run it
              chmod +x /tmp/setup.sh
              sudo /tmp/setup.sh
              EOF

  tags = {
    Name = "app-server"
  }
}

# RDS Instance
resource "aws_db_instance" "postgres" {
  allocated_storage       = 20  # Free tier includes 20GB
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "17.2"
  instance_class         = "db.t3.micro"  # Free tier eligible
  identifier             = "app-db"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  parameter_group_name   = "default.postgres17"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  backup_retention_period = 0  # Disable automated backups to stay within free tier
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  publicly_accessible    = false
  storage_encrypted      = false  # Disable encryption to stay within free tier
  monitoring_interval    = 0  # Disable enhanced monitoring to stay within free tier
  multi_az               = false  # Disable multi-AZ to stay within free tier
  availability_zone      = "${var.aws_region}a"  # Specify AZ to ensure consistent placement
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]

  tags = {
    Name = "main-db-subnet-group"
  }
}

# SSH Key
resource "aws_key_pair" "deployer" {
  key_name   = "aws-nazarslbn"
  public_key = file("~/.ssh/aws-nazarslbn.pub")
} 