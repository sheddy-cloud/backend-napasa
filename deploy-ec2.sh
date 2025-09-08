#!/bin/bash

# NAPASA Backend EC2 Deployment Script
# Run this script on your EC2 instance

echo "🚀 Starting NAPASA Backend Deployment on EC2..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js (if not already installed)
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install PM2 for process management
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2..."
    sudo npm install -g pm2
fi

# Install Git (if not already installed)
if ! command -v git &> /dev/null; then
    echo "📦 Installing Git..."
    sudo apt install -y git
fi

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /opt/napasa-backend
sudo chown $USER:$USER /opt/napasa-backend
cd /opt/napasa-backend

# Clone or update repository (replace with your actual repo URL)
echo "📥 Cloning repository..."
if [ -d ".git" ]; then
    echo "🔄 Updating existing repository..."
    git pull origin main
else
    echo "📥 Cloning new repository..."
    # Replace with your actual repository URL
    git clone https://github.com/sheddy-cloud/backend-napasa.git .
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install --production

# Copy environment file
echo "⚙️ Setting up environment..."
if [ ! -f ".env" ]; then
    cp env.production .env
    echo "✅ Environment file created from production template"
    echo "⚠️ Please edit .env file with your actual values"
fi

# Create uploads directory
echo "📁 Creating uploads directory..."
mkdir -p uploads
chmod 755 uploads

# Create logs directory
echo "📁 Creating logs directory..."
mkdir -p logs
chmod 755 logs

# Setup PM2 ecosystem file
echo "⚙️ Setting up PM2 configuration..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'napasa-backend',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 5000,
      HOST: '0.0.0.0'
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# Start the application with PM2
echo "🚀 Starting application with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup

echo "✅ Deployment completed!"
echo "🌐 Your API should be available at: http://13.51.162.253:5000"
echo "🏥 Health check: http://13.51.162.253:5000/health"
echo ""
echo "📋 Useful commands:"
echo "  pm2 status          - Check application status"
echo "  pm2 logs            - View logs"
echo "  pm2 restart napasa-backend - Restart application"
echo "  pm2 stop napasa-backend    - Stop application"
echo ""
echo "⚠️ Don't forget to:"
echo "  1. Configure your EC2 security group to allow port 5000"
echo "  2. Update your Flutter app to use http://13.51.162.253:5000/api"
echo "  3. Edit .env file with your actual configuration"
