#!/bin/bash

echo "🏗️ Restructuring NAPASA Backend for Sequelize"
echo "============================================="

# Create new clean structure
echo "1. Creating new directory structure..."
mkdir -p src/{models,routes,middleware,controllers,config,utils}
mkdir -p src/database/{migrations,seeders}
mkdir -p logs uploads

# Move and organize files
echo "2. Moving files to new structure..."

# Move database config
mv src/database/config.js src/config/database.js

# Move middleware
mv middleware/* src/middleware/
rmdir middleware

# Move routes
mv routes/* src/routes/
rmdir routes

# Move models (we'll keep only the converted ones)
mv src/models/User.js src/models/
rm -rf models/  # Remove old Mongoose models

# Create new server.js in root that imports from src
echo "3. Creating new server.js..."
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Import database
const { sequelize, testConnection, syncDatabase } = require('./src/config/database');

// Import middleware
const errorHandler = require('./src/middleware/errorHandler');
const notFound = require('./src/middleware/notFound');

// Import routes
const authRoutes = require('./src/routes/auth');
const userRoutes = require('./src/routes/users');

const app = express();

// Security middleware
app.use(helmet());
app.use(compression());

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests from this IP, please try again later.'
  }
});
app.use('/api/', limiter);

// CORS configuration
app.use(cors({
  origin: process.env.CLIENT_URL || 'http://localhost:3000',
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Static files
app.use('/uploads', express.static('uploads'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'NAPASA Main Backend API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    database: 'PostgreSQL'
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// Error handling middleware
app.use(notFound);
app.use(errorHandler);

// Database connection
const connectDB = async () => {
  try {
    const isConnected = await testConnection();
    if (isConnected) {
      await syncDatabase(false);
      console.log('✅ PostgreSQL database connected and synchronized');
    } else {
      throw new Error('Database connection failed');
    }
  } catch (error) {
    console.error('Database connection error:', error.message);
    process.exit(1);
  }
};

// Start server
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || 'localhost';

const startServer = async () => {
  await connectDB();
  
  app.listen(PORT, HOST, () => {
    console.log(`🚀 NAPASA Main Backend Server running on ${HOST}:${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🌐 Health check: http://${HOST}:${PORT}/health`);
    console.log(`🌐 API Base URL: http://${HOST}:${PORT}/api`);
  });
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  console.log(`Error: ${err.message}`);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.log(`Error: ${err.message}`);
  process.exit(1);
});

startServer();

module.exports = app;
EOF

# Update import paths in routes
echo "4. Updating import paths in routes..."

# Update auth.js
sed -i "s|require('../src/models/User')|require('../models/User')|g" src/routes/auth.js
sed -i "s|require('../middleware/auth')|require('../middleware/auth')|g" src/routes/auth.js

# Update users.js
sed -i "s|require('../src/models/User')|require('../models/User')|g" src/routes/users.js
sed -i "s|require('../middleware/auth')|require('../middleware/auth')|g" src/routes/users.js

# Update middleware paths
find src/middleware -name "*.js" -exec sed -i "s|require('../models/|require('../models/|g" {} \;

echo ""
echo "🎉 Backend restructuring completed!"
echo ""
echo "📁 New structure:"
echo "   backend/"
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
echo "   ├── package.json"
echo "   └── .env"
echo ""
echo "📋 Next steps:"
echo "   1. Test the restructured backend"
echo "   2. Deploy to server"
echo "   3. Convert remaining models as needed"
echo ""
