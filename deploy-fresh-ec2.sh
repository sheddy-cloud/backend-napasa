#!/bin/bash

echo "🚀 Deploying NAPASA Main Backend to Fresh EC2 Instance"
echo "====================================================="
echo "Instance IP: 13.53.234.190"
echo ""

# Update system
echo "1. Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "2. Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    net-tools \
    htop \
    unzip

# Install Node.js 18
echo "3. Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2
echo "4. Installing PM2..."
sudo npm install -g pm2

# Install Nginx
echo "5. Installing Nginx..."
sudo apt install -y nginx

# Create application directory
echo "6. Setting up application directory..."
sudo mkdir -p /opt/napasa-backend
sudo chown -R ubuntu:ubuntu /opt/napasa-backend

# Copy application files (assuming we're running from the backend folder)
echo "7. Copying application files..."
cp -r . /opt/napasa-backend/
cd /opt/napasa-backend

# Install Node.js dependencies
echo "8. Installing Node.js dependencies..."
npm install

# Create environment file
echo "9. Creating environment file..."
cat > .env << 'EOF'
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
MONGODB_URI=mongodb+srv://shedcodes:SHEDRACKs.677@cluster1.l5p3lpp.mongodb.net/napasa?retryWrites=true&w=majority&appName=Cluster1
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-2024
JWT_EXPIRE=7d
CLIENT_URL=http://13.53.234.190:5000,http://localhost:3000,http://localhost:8080,http://10.0.2.2:5000
EOF

# Create PM2 ecosystem file
echo "10. Creating PM2 configuration..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
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
      error_file: './logs/backend-err.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true
    }
  ]
};
EOF

# Create logs directory
mkdir -p logs

# Start application with PM2
echo "11. Starting application with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup
pm2 startup

echo "12. Configuring Nginx..."
# Create Nginx configuration
sudo tee /etc/nginx/sites-available/napasa-backend > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    # API routes
    location /api/ {
        proxy_pass http://127.0.0.1:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:5000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files (uploads) with caching
    location /uploads/ {
        alias /opt/napasa-backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff";
    }

    # Default location - redirect to backend
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/napasa-backend /etc/nginx/sites-enabled/

# Test and start Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# Configure firewall
echo "13. Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 5000/tcp
sudo ufw --force enable

# Wait for services to start
echo "14. Waiting for services to start..."
sleep 15

# Test services
echo "15. Testing services..."
echo "   Testing Backend (direct)..."
if curl -s --connect-timeout 5 http://127.0.0.1:5000/health; then
    echo "   ✅ Backend direct connection works"
else
    echo "   ❌ Backend direct connection failed"
fi

echo "   Testing Backend (via Nginx)..."
if curl -s --connect-timeout 5 http://localhost/health; then
    echo "   ✅ Backend via Nginx works"
else
    echo "   ❌ Backend via Nginx failed"
fi

echo "   Testing API endpoint (via Nginx)..."
if curl -s --connect-timeout 5 http://localhost/api/health; then
    echo "   ✅ API endpoint via Nginx works"
else
    echo "   ❌ API endpoint via Nginx failed"
fi

# Show status
echo ""
echo "16. Final status check..."
pm2 status

echo ""
echo "🎉 Main Backend Deployment completed!"
echo ""
echo "📋 Your Main Backend endpoints:"
echo "   🌐 Backend: http://13.53.234.190/health"
echo "   🌐 API: http://13.53.234.190/api/health"
echo "   🌐 Direct: http://13.53.234.190:5000/health"
echo ""
echo "📋 Next steps:"
echo "   1. Update EC2 Security Groups in AWS Console"
echo "   2. Open ports: 80, 5000 (Source: 0.0.0.0/0)"
echo "   3. Test external access"
echo "   4. Update Flutter app to use new backend URL"
echo ""
echo "📋 Useful commands:"
echo "   pm2 status                    # Check app status"
echo "   pm2 logs napasa-backend       # View backend logs"
echo "   sudo systemctl status nginx   # Check Nginx"







