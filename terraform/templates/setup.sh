#!/bin/bash

# Exit on error and log all output
set -e
exec > >(tee /var/log/setup.log) 2>&1

echo "Starting system setup..."

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y netcat-openbsd git

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Create app directory with proper permissions
echo "Creating application directory..."
sudo mkdir -p /app
sudo chown -R ubuntu:ubuntu /app

# Clone repository
echo "Cloning repository..."
git clone ${repository_url} /app
cd /app

# Install dependencies
echo "Installing application dependencies..."
npm install

# Create .env file from template
echo "Creating environment configuration..."
cat > .env << EOL
DB_USER=${db_username}
DB_PASS=${db_password}
DB_HOST=${db_host}
DB_PORT=5432
DB_NAME=${db_name}
NODE_ENV=production
EOL

# Source environment variables
echo "Loading environment variables..."
set -a
source .env
set +a

# Wait for database to be ready
echo "Waiting for database to be ready..."
while ! nc -z ${db_host} 5432; do
  sleep 1
done
echo "Database is ready!"

# Run database migrations
echo "Running database migrations..."
# First, try to create the database using Sequelize
npx sequelize-cli db:create || true
# Then run migrations
npm run migration:run

# Build application
echo "Building application..."
npm run build

# Install PM2 for process management
echo "Installing PM2..."
sudo npm install -g pm2

# Start application with PM2
echo "Starting application with PM2..."
pm2 start dist/main.js --name "app"

# Configure PM2 to start on system boot
echo "Configuring PM2 startup..."
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save

# Set up log rotation
echo "Setting up log rotation..."
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7

# Install deployment script
echo "Installing deployment script..."
cat > /usr/local/bin/deploy << 'EOL'
#!/bin/bash
cd /app
git pull origin main
npm install
# Source environment variables
set -a
source .env
set +a
npm run migration:run
npm run build
pm2 restart app
EOL

# Make deployment script executable
chmod +x /usr/local/bin/deploy

echo "Setup completed successfully!" 