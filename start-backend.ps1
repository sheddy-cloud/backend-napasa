# NAPASA Backend Setup Script for Windows
Write-Host "🚀 NAPASA Backend Setup Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if Node.js is installed
Write-Host "`n🔍 Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js v18+ from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Check if MongoDB is running
Write-Host "`n🔍 Checking MongoDB connection..." -ForegroundColor Yellow
try {
    $mongoTest = mongo --eval "db.runCommand('ping')" --quiet 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MongoDB is running" -ForegroundColor Green
    } else {
        Write-Host "⚠️  MongoDB might not be running. Please start MongoDB service." -ForegroundColor Yellow
        Write-Host "   You can start it with: net start MongoDB" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️  MongoDB command not found. Please ensure MongoDB is installed and in PATH." -ForegroundColor Yellow
}

# Install dependencies
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green

# Create .env file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "`n📝 Creating .env file..." -ForegroundColor Yellow
    Copy-Item "env.example" ".env"
    Write-Host "✅ .env file created from template" -ForegroundColor Green
    Write-Host "⚠️  Please edit .env file with your configuration" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ .env file already exists" -ForegroundColor Green
}

# Setup database
Write-Host "`n🗄️  Setting up database..." -ForegroundColor Yellow
node setup.js
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Database setup failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit .env file with your configuration" -ForegroundColor White
Write-Host "2. Start the server: npm run dev" -ForegroundColor White
Write-Host "3. Visit: http://localhost:5000/health" -ForegroundColor White
Write-Host "`n🔑 Sample accounts created:" -ForegroundColor Cyan
Write-Host "Admin: admin@napasa.com / admin123" -ForegroundColor White
Write-Host "Tourist: john.tourist@example.com / password123" -ForegroundColor White
Write-Host "Agency: agency@example.com / password123" -ForegroundColor White

Write-Host "`n🚀 Starting development server..." -ForegroundColor Green
npm run dev
