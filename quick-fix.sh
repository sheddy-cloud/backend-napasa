#!/bin/bash

echo "🚀 NAPASA Backend Quick Fix Script"
echo "=================================="

# Navigate to application directory
cd /opt/napasa-backend

echo "1. Checking if we're in the right directory..."
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Please run the full deployment script first."
    exit 1
fi
echo "✅ Found package.json"

echo ""
echo "2. Installing dependencies..."
npm install --production

echo ""
echo "3. Setting up environment file..."
if [ ! -f ".env" ]; then
    if [ -f "env.production" ]; then
        cp env.production .env
        echo "✅ Created .env from env.production"
    else
        echo "❌ No environment file found. Creating basic .env..."
        cat > .env << 'EOF'
PORT=5000
NODE_ENV=production
HOST=0.0.0.0
MONGODB_URI=mongodb+srv://shedcodes:SHEDRACKs.677@cluster1.l5p3lpp.mongodb.net/napasa?retryWrites=true&w=majority&appName=Cluster1
JWT_SECRET=napasa_production_jwt_secret_2024_secure_key
JWT_EXPIRE=7d
CLIENT_URL=http://13.51.162.253,http://localhost:3000,http://localhost:8080
EOF
        echo "✅ Created basic .env file"
    fi
else
    echo "✅ .env file already exists"
fi

echo ""
echo "4. Creating uploads directory..."
mkdir -p uploads
chmod 755 uploads

echo ""
echo "5. Creating logs directory..."
mkdir -p logs
chmod 755 logs

echo ""
echo "6. Starting application with PM2..."
pm2 stop napasa-backend 2>/dev/null || true
pm2 delete napasa-backend 2>/dev/null || true
pm2 start ecosystem.config.js

echo ""
echo "7. Checking PM2 status..."
pm2 status

echo ""
echo "8. Testing local connection..."
sleep 3
if curl -s --connect-timeout 5 http://localhost:5000/health; then
    echo "✅ Backend is running on localhost:5000"
else
    echo "❌ Backend is not responding. Checking logs..."
    pm2 logs napasa-backend --lines 10 --nostream
fi

echo ""
echo "9. Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

echo ""
echo "10. Testing Nginx connection..."
if curl -s --connect-timeout 5 http://localhost/health; then
    echo "✅ Nginx is working and proxying to backend"
else
    echo "❌ Nginx is not working. Checking configuration..."
    sudo nginx -t
fi

echo ""
echo "🎉 Quick fix completed!"
echo ""
echo "📋 Test your endpoints:"
echo "curl http://13.51.162.253:5000/health  # Direct to Node.js"
echo "curl http://13.51.162.253/health       # Via Nginx"
echo ""
echo "📋 Useful commands:"
echo "pm2 status                    # Check app status"
echo "pm2 logs napasa-backend       # View logs"
echo "sudo systemctl status nginx   # Check Nginx"






