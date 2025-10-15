#!/bin/bash

echo "🚀 Deploying Clean NAPASA Main Backend"
echo "======================================"

# Create PostgreSQL database and user
echo "1. Creating PostgreSQL database..."
sudo -u postgres psql -c "CREATE DATABASE napasa_main_backend;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER napasa_main_user WITH PASSWORD 'napasa_main_password';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE napasa_main_backend TO napasa_main_user;" 2>/dev/null
sudo -u postgres psql -c "ALTER USER napasa_main_user CREATEDB;" 2>/dev/null

# Create application directory
echo "2. Setting up application directory..."
sudo mkdir -p /var/www/napasa-main-backend
sudo chown -R ubuntu:ubuntu /var/www/napasa-main-backend

# Copy clean files
echo "3. Copying clean files..."
cp server-clean.js /var/www/napasa-main-backend/server.js
cp package.json /var/www/napasa-main-backend/
cp -r src/ /var/www/napasa-main-backend/

cd /var/www/napasa-main-backend

# Install dependencies
echo "4. Installing dependencies..."
npm install

# Create environment file
echo "5. Creating environment file..."
cat > .env << 'EOF'
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
DB_HOST=localhost
DB_PORT=5432
DB_NAME=napasa_main_backend
DB_USER=napasa_main_user
DB_PASSWORD=napasa_main_password
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
CLIENT_URL=http://localhost:3000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Create logs directory
mkdir -p logs

# Create PM2 ecosystem file
echo "6. Creating PM2 configuration..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'napasa-main-backend',
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
      error_file: './logs/main-backend-err.log',
      out_file: './logs/main-backend-out.log',
      log_file: './logs/main-backend-combined.log',
      time: true
    }
  ]
};
EOF

# Stop existing main backend if running
echo "7. Stopping existing main backend..."
pm2 stop napasa-main-backend 2>/dev/null || echo "No existing process to stop"
pm2 delete napasa-main-backend 2>/dev/null || echo "No existing process to delete"

# Start application with PM2
echo "8. Starting clean backend with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

echo ""
echo "🎉 Clean Main Backend deployment completed!"
echo ""
echo "📁 Clean structure deployed:"
echo "   /var/www/napasa-main-backend/"
echo "   ├── src/"
echo "   │   ├── config/"
echo "   │   │   └── database.js"
echo "   │   ├── models/"
echo "   │   │   └── User.js"
echo "   │   ├── routes/"
echo "   │   │   ├── auth.js"
echo "   │   │   └── users.js"
echo "   │   └── middleware/"
echo "   │       ├── auth.js"
echo "   │       ├── errorHandler.js"
echo "   │       └── notFound.js"
echo "   ├── server.js"
echo "   └── package.json"
echo ""
echo "📋 Check status:"
echo "   pm2 status"
echo "   pm2 logs napasa-main-backend"
echo ""
echo "📋 Test endpoints:"
echo "   curl http://localhost:5000/health"
echo "   curl http://localhost:5000/api/auth/register"
echo ""

