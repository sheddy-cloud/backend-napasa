# NAPASA Backend EC2 Deployment Guide

## 🚀 Quick Deployment Steps

### 1. Prepare Your EC2 Instance

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@13.51.162.253

# Update system
sudo apt update && sudo apt upgrade -y
```

### 2. Upload Your Code

**Option A: Using Git (Recommended)**
```bash
# Clone your repository
git clone https://github.com/yourusername/napasa-backend.git
cd napasa-backend/backend
```

**Option B: Using SCP**
```bash
# From your local machine
scp -i your-key.pem -r backend/ ubuntu@13.51.162.253:/home/ubuntu/
```

### 3. Run the Deployment Script

```bash
# Make the script executable
chmod +x deploy-ec2.sh

# Run the deployment script
./deploy-ec2.sh
```

### 4. Configure Environment

```bash
# Edit the environment file
nano .env

# Make sure these values are correct:
# MONGODB_URI=your-mongodb-connection-string
# JWT_SECRET=your-secure-jwt-secret
# CLIENT_URL=http://13.51.162.253:5000,http://localhost:3000
```

### 5. Start the Application

```bash
# Start with PM2
npm run pm2:start

# Check status
npm run pm2:status

# View logs
npm run pm2:logs
```

## 🔧 EC2 Security Group Configuration

Make sure your EC2 security group allows:

| Type | Protocol | Port Range | Source |
|------|----------|------------|---------|
| HTTP | TCP | 80 | 0.0.0.0/0 |
| HTTP | TCP | 5000 | 0.0.0.0/0 |
| HTTPS | TCP | 443 | 0.0.0.0/0 (for future SSL) |
| SSH | TCP | 22 | Your IP |

## 📱 Update Flutter App

Your Flutter app is already configured to use the EC2 backend in production mode.

**For testing with EC2:**
```dart
// Temporarily change in lib/core/services/api_service.dart
static const String baseUrl = 'http://13.51.162.253:5000/api';
```

## 🏥 Health Check

Test your deployment:
```bash
# Via Nginx (recommended)
curl http://13.51.162.253/health

# Direct to Node.js (for debugging)
curl http://13.51.162.253:5000/health
```

Expected response:
```json
{
  "status": "success",
  "message": "NAPASA Backend API is running",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "environment": "production"
}
```

## 📋 Useful Commands

```bash
# PM2 Commands
pm2 status                    # Check application status
pm2 logs napasa-backend       # View application logs
pm2 restart napasa-backend    # Restart application
pm2 stop napasa-backend       # Stop application
pm2 monit                     # Monitor resources

# Nginx Commands
sudo systemctl status nginx   # Check Nginx status
sudo systemctl reload nginx   # Reload Nginx configuration
sudo systemctl restart nginx  # Restart Nginx
sudo nginx -t                 # Test Nginx configuration
sudo tail -f /var/log/nginx/access.log  # View access logs
sudo tail -f /var/log/nginx/error.log   # View error logs
```

## 🔍 Troubleshooting

### Application won't start
```bash
# Check logs
pm2 logs napasa-backend

# Check if port is in use
sudo netstat -tlnp | grep :5000
```

### Can't connect from Flutter app
1. Check EC2 security group allows port 5000
2. Verify application is running: `pm2 status`
3. Test health endpoint: `curl http://13.51.162.253:5000/health`

### MongoDB connection issues
1. Check your MongoDB Atlas IP whitelist includes EC2 IP
2. Verify MONGODB_URI in .env file
3. Check MongoDB connection logs

## 🌐 Your API Endpoints

Once deployed, your API will be available at:

### Via Nginx (Recommended)
- **Base URL**: `http://13.51.162.253/api`
- **Health Check**: `http://13.51.162.253/health`
- **Register**: `POST http://13.51.162.253/api/auth/register`
- **Login**: `POST http://13.51.162.253/api/auth/login`

### Direct to Node.js (For Debugging)
- **Base URL**: `http://13.51.162.253:5000/api`
- **Health Check**: `http://13.51.162.253:5000/health`
- **Register**: `POST http://13.51.162.253:5000/api/auth/register`
- **Login**: `POST http://13.51.162.253:5000/api/auth/login`

## 🔄 Updates and Maintenance

```bash
# Pull latest changes
git pull origin main

# Install new dependencies
npm install

# Restart application
pm2 restart napasa-backend
```

## 📊 Monitoring

PM2 provides built-in monitoring:
```bash
# Real-time monitoring
pm2 monit

# View detailed status
pm2 show napasa-backend
```

Your NAPASA backend is now ready for production! 🎉
