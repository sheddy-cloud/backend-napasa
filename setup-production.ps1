# NAPASA Backend Production Setup Script
# This script helps you set up the production environment

Write-Host "🚀 Setting up NAPASA Backend for Production..." -ForegroundColor Green

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js first." -ForegroundColor Red
    exit 1
}

# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Host "✅ npm version: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm is not installed. Please install npm first." -ForegroundColor Red
    exit 1
}

# Create .env file from production template
if (Test-Path "env.production") {
    Copy-Item "env.production" ".env"
    Write-Host "✅ Created .env file from production template" -ForegroundColor Green
} else {
    Write-Host "❌ env.production template not found" -ForegroundColor Red
    exit 1
}

# Prompt for MongoDB password
Write-Host ""
Write-Host "🔐 Please enter your MongoDB Atlas password:" -ForegroundColor Yellow
$mongoPassword = Read-Host -AsSecureString
$mongoPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($mongoPassword))

# Update .env file with MongoDB password
$envContent = Get-Content ".env" -Raw
$envContent = $envContent -replace "YOUR_ACTUAL_PASSWORD", $mongoPasswordPlain
Set-Content ".env" $envContent
Write-Host "✅ Updated MongoDB connection string" -ForegroundColor Green

# Prompt for JWT secret
Write-Host ""
Write-Host "🔑 Please enter a secure JWT secret (or press Enter to use default):" -ForegroundColor Yellow
$jwtSecret = Read-Host
if ([string]::IsNullOrWhiteSpace($jwtSecret)) {
    $jwtSecret = "napasa_production_jwt_secret_$(Get-Date -Format 'yyyyMMdd')_$(Get-Random -Minimum 1000 -Maximum 9999)"
}

# Update .env file with JWT secret
$envContent = Get-Content ".env" -Raw
$envContent = $envContent -replace "napasa_production_jwt_secret_2024_secure_key_change_this", $jwtSecret
Set-Content ".env" $envContent
Write-Host "✅ Updated JWT secret" -ForegroundColor Green

# Prompt for production domain
Write-Host ""
Write-Host "🌐 Please enter your production domain (or press Enter to use localhost):" -ForegroundColor Yellow
$productionDomain = Read-Host
if ([string]::IsNullOrWhiteSpace($productionDomain)) {
    $productionDomain = "http://localhost:3000"
} else {
    if (-not $productionDomain.StartsWith("http")) {
        $productionDomain = "https://$productionDomain"
    }
}

# Update .env file with production domain
$envContent = Get-Content ".env" -Raw
$envContent = $envContent -replace "https://your-domain.com", $productionDomain
Set-Content ".env" $envContent
Write-Host "✅ Updated production domain" -ForegroundColor Green

# Install dependencies
Write-Host ""
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Create necessary directories
Write-Host ""
Write-Host "📁 Creating necessary directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "uploads" | Out-Null
New-Item -ItemType Directory -Force -Path "logs" | Out-Null
Write-Host "✅ Created uploads and logs directories" -ForegroundColor Green

# Test MongoDB connection
Write-Host ""
Write-Host "🔍 Testing MongoDB connection..." -ForegroundColor Yellow
node -e "
const mongoose = require('mongoose');
require('dotenv').config();
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ MongoDB connection successful');
    process.exit(0);
  })
  .catch((err) => {
    console.log('❌ MongoDB connection failed:', err.message);
    process.exit(1);
  });
"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ MongoDB connection test passed" -ForegroundColor Green
} else {
    Write-Host "❌ MongoDB connection test failed" -ForegroundColor Red
    Write-Host "Please check your MongoDB credentials and network connection" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Production setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the .env file and update any other settings as needed" -ForegroundColor White
Write-Host "2. Run 'npm start' to start the production server" -ForegroundColor White
Write-Host "3. Test your API endpoints" -ForegroundColor White
Write-Host ""
Write-Host "Your API will be available at: http://localhost:5000" -ForegroundColor Yellow
Write-Host "Health check: http://localhost:5000/health" -ForegroundColor Yellow
