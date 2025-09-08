#!/bin/bash

echo "🔍 NAPASA Backend Troubleshooting Script"
echo "========================================"

# Check if we're on the EC2 instance
echo "1. Checking system information..."
echo "   Hostname: $(hostname)"
echo "   IP Address: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'Not available')"
echo "   Current user: $(whoami)"
echo "   Current directory: $(pwd)"
echo ""

# Check if Node.js is installed
echo "2. Checking Node.js installation..."
if command -v node &> /dev/null; then
    echo "   ✅ Node.js version: $(node --version)"
    echo "   ✅ NPM version: $(npm --version)"
else
    echo "   ❌ Node.js is not installed"
    exit 1
fi
echo ""

# Check if PM2 is installed
echo "3. Checking PM2 installation..."
if command -v pm2 &> /dev/null; then
    echo "   ✅ PM2 is installed"
    echo "   PM2 processes:"
    pm2 status
else
    echo "   ❌ PM2 is not installed"
fi
echo ""

# Check if Nginx is installed and running
echo "4. Checking Nginx..."
if command -v nginx &> /dev/null; then
    echo "   ✅ Nginx is installed"
    echo "   Nginx status:"
    sudo systemctl status nginx --no-pager -l
else
    echo "   ❌ Nginx is not installed"
fi
echo ""

# Check if the application directory exists
echo "5. Checking application directory..."
if [ -d "/opt/napasa-backend" ]; then
    echo "   ✅ Application directory exists: /opt/napasa-backend"
    echo "   Directory contents:"
    ls -la /opt/napasa-backend/
else
    echo "   ❌ Application directory does not exist: /opt/napasa-backend"
fi
echo ""

# Check if package.json exists
echo "6. Checking package.json..."
if [ -f "/opt/napasa-backend/package.json" ]; then
    echo "   ✅ package.json exists"
    echo "   Dependencies installed:"
    if [ -d "/opt/napasa-backend/node_modules" ]; then
        echo "   ✅ node_modules directory exists"
    else
        echo "   ❌ node_modules directory missing - run 'npm install'"
    fi
else
    echo "   ❌ package.json does not exist"
fi
echo ""

# Check if .env file exists
echo "7. Checking environment configuration..."
if [ -f "/opt/napasa-backend/.env" ]; then
    echo "   ✅ .env file exists"
    echo "   Environment variables (without sensitive data):"
    grep -E "^(PORT|NODE_ENV|HOST)=" /opt/napasa-backend/.env 2>/dev/null || echo "   No PORT/NODE_ENV/HOST found"
else
    echo "   ❌ .env file does not exist"
    echo "   Available env files:"
    ls -la /opt/napasa-backend/env* 2>/dev/null || echo "   No env files found"
fi
echo ""

# Check if port 5000 is in use
echo "8. Checking port 5000..."
if sudo netstat -tlnp | grep :5000; then
    echo "   ✅ Port 5000 is in use"
else
    echo "   ❌ Port 5000 is not in use"
fi
echo ""

# Check if port 80 is in use (Nginx)
echo "9. Checking port 80..."
if sudo netstat -tlnp | grep :80; then
    echo "   ✅ Port 80 is in use (Nginx should be running)"
else
    echo "   ❌ Port 80 is not in use"
fi
echo ""

# Check PM2 logs
echo "10. Checking PM2 logs (last 20 lines)..."
if command -v pm2 &> /dev/null; then
    pm2 logs napasa-backend --lines 20 --nostream 2>/dev/null || echo "   No PM2 logs available"
else
    echo "   PM2 not available"
fi
echo ""

# Check Nginx logs
echo "11. Checking Nginx logs..."
if [ -f "/var/log/nginx/error.log" ]; then
    echo "   Recent Nginx errors:"
    sudo tail -10 /var/log/nginx/error.log
else
    echo "   No Nginx error log found"
fi
echo ""

# Check system logs
echo "12. Checking system logs for Node.js..."
sudo journalctl -u nginx --no-pager -l --since "1 hour ago" | tail -5
echo ""

# Test local connection
echo "13. Testing local connections..."
echo "   Testing localhost:5000..."
if curl -s --connect-timeout 5 http://localhost:5000/health; then
    echo "   ✅ Backend responds on localhost:5000"
else
    echo "   ❌ Backend does not respond on localhost:5000"
fi

echo "   Testing localhost:80..."
if curl -s --connect-timeout 5 http://localhost/health; then
    echo "   ✅ Nginx responds on localhost:80"
else
    echo "   ❌ Nginx does not respond on localhost:80"
fi
echo ""

# Check firewall/security groups
echo "14. Checking firewall status..."
if command -v ufw &> /dev/null; then
    echo "   UFW status:"
    sudo ufw status
else
    echo "   UFW not installed"
fi
echo ""

echo "🔧 Suggested fixes:"
echo "==================="
echo "1. If PM2 is not running: cd /opt/napasa-backend && pm2 start ecosystem.config.js"
echo "2. If Nginx is not running: sudo systemctl start nginx"
echo "3. If .env is missing: cp env.production .env && edit .env"
echo "4. If dependencies missing: cd /opt/napasa-backend && npm install"
echo "5. Check EC2 security group allows ports 80 and 5000"
echo ""
echo "📋 Useful commands:"
echo "==================="
echo "pm2 status                    # Check PM2 status"
echo "pm2 logs napasa-backend       # View PM2 logs"
echo "pm2 restart napasa-backend    # Restart app"
echo "sudo systemctl status nginx   # Check Nginx status"
echo "sudo systemctl restart nginx  # Restart Nginx"
echo "sudo nginx -t                 # Test Nginx config"
