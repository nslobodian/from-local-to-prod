# SSH Key
resource "aws_key_pair" "deployer" {
  key_name   = "${var.app_name}-deployer"
  public_key = file(var.ssh_key_path)
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                         = var.ami_id
  instance_type              = "t2.micro"  # Free tier eligible
  subnet_id                  = aws_subnet.public.id
  vpc_security_group_ids     = [aws_security_group.ec2.id]
  key_name                   = aws_key_pair.deployer.key_name
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
                db_app_username = var.db_app_username
                db_app_password = var.db_app_password
                db_migration_username = var.db_migration_username
                db_migration_password = var.db_migration_password
              })}
              EOS
              
              # Make script executable and run it
              chmod +x /tmp/setup.sh
              sudo /tmp/setup.sh
              EOF

  tags = {
    Name = "${var.app_name}-server"
  }
} 