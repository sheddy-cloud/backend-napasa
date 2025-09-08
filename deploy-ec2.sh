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

# Install Nginx (if not already installed)
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing Nginx..."
    sudo apt install -y nginx
fi

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /opt/napasa-backend
sudo chown $USER:$USER /opt/napasa-backend
cd /opt/napasa-backend
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

# Configure Nginx
echo "⚙️ Configuring Nginx..."

# Remove existing configuration if it exists
sudo rm -f /etc/nginx/sites-available/napasa-backend
sudo rm -f /etc/nginx/sites-enabled/napasa-backend

sudo tee /etc/nginx/sites-available/napasa-backend > /dev/null << 'EOF'
server {
    listen 80;
    server_name 13.51.162.253;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    # API routes
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files (uploads)
    location /uploads/ {
        alias /opt/napasa-backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Default location
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/napasa-backend /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🔍 Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # Start and enable Nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo systemctl reload nginx
    
    echo "✅ Nginx started and enabled"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo "✅ Deployment completed!"
echo "🌐 Your API is now available at:"
echo "   - Direct: http://13.51.162.253:5000"
echo "   - Via Nginx: http://13.51.162.253"
echo "🏥 Health check: http://13.51.162.253/health"
echo "📡 API Base URL: http://13.51.162.253/api"
echo ""
echo "📋 Useful commands:"
echo "  pm2 status                    - Check application status"
echo "  pm2 logs                      - View application logs"
echo "  pm2 restart napasa-backend    - Restart application"
echo "  pm2 stop napasa-backend       - Stop application"
echo "  sudo systemctl status nginx   - Check Nginx status"
echo "  sudo systemctl reload nginx   - Reload Nginx config"
echo "  sudo nginx -t                 - Test Nginx configuration"
echo ""
echo "⚠️ Don't forget to:"
echo "  1. Configure your EC2 security group to allow ports 80 and 5000"
echo "  2. Update your Flutter app to use http://13.51.162.253/api"
echo "  3. Edit .env file with your actual configuration"
echo "  4. Consider setting up SSL certificate for HTTPS"
