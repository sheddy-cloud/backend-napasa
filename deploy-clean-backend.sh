#!/bin/bash

echo "🚀 Deploying NAPASA Main Backend with PostgreSQL"
echo "=============================================="

# --------------------------
# STEP 0: Root Privilege Check
# --------------------------
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo ./deploy.sh)"
  exit 1
fi

# --------------------------
# STEP 1: System Update & Dependencies
# --------------------------
echo "1. Updating system packages..."
apt update -y && apt upgrade -y

# --------------------------
# STEP 2: Install Node.js + npm + PM2
# --------------------------
echo "2. Installing Node.js, npm, and PM2..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt install -y nodejs
fi

if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
fi

node -v
npm -v
pm2 -v

# --------------------------
# STEP 3: Install PostgreSQL
# --------------------------
echo "3. Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

if systemctl is-active --quiet postgresql; then
  echo "✅ PostgreSQL is running"
else
  echo "❌ PostgreSQL failed to start"
  exit 1
fi

# --------------------------
# STEP 4: Create Database & User
# --------------------------
echo "4. Setting up PostgreSQL database and user..."
sudo -u postgres psql -c "CREATE DATABASE napasa_main_backend;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER shedrack WITH PASSWORD 'SHEDRACKs.677';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE napasa_main_backend TO shedrack;"
sudo -u postgres psql -c "ALTER USER shedrack CREATEDB;"

# --------------------------
# STEP 5: Set Up Application Directory
# --------------------------
echo "5. Setting up application directory..."
APP_DIR="/var/www/napasa-main-backend"
mkdir -p $APP_DIR
chown -R ubuntu:ubuntu $APP_DIR

# --------------------------
# STEP 6: Copy Application Files
# --------------------------
echo "6. Copying application files..."
rsync -av --exclude='.git' --exclude='node_modules' . $APP_DIR/
cd $APP_DIR

# --------------------------
# STEP 7: Install Backend Dependencies
# --------------------------
echo "7. Installing Node.js dependencies..."
sudo -u ubuntu npm install --production

# --------------------------
# STEP 8: Create Environment File
# --------------------------
echo "8. Creating environment file..."
cat > .env << 'EOF'
NODE_ENV=production
PORT=5000
HOST=0.0.0.0

DB_HOST=localhost
DB_PORT=5432
DB_NAME=napasa_main_backend
DB_USER=shedrack
DB_PASSWORD=SHEDRACKs.677

JWT_SECRET=SHEDRACKs.677
JWT_EXPIRE=7d

CLIENT_URL=http://localhost:3000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# --------------------------
# STEP 9: Create Logs Directory
# --------------------------
mkdir -p logs
chown -R ubuntu:ubuntu logs

# --------------------------
# STEP 10: Create PM2 Config File
# --------------------------
echo "9. Creating PM2 ecosystem configuration..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'napasa-main-backend',
      script: 'server_clean.js',
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

# --------------------------
# STEP 11: Start Backend with PM2
# --------------------------
echo "10. Starting NAPASA backend with PM2..."
sudo -u ubuntu pm2 start ecosystem.config.js
sudo -u ubuntu pm2 save
sudo -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu

# --------------------------
# STEP 12: Summary
# --------------------------
echo ""
echo "🎉 NAPASA Main Backend deployed successfully!"
echo ""
echo "📋 To check status:"
echo "   pm2 status"
echo "   pm2 logs napasa-main-backend"
echo ""
echo "📋 Test endpoints:"
echo "   curl http://localhost:5000/health"
echo "   curl http://<YOUR-SERVER-IP>:5000/health"
echo ""
echo "✅ Deployment Completed!"
