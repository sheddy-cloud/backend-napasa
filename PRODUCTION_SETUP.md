# NAPASA Backend - Production Setup Guide

## 🚀 Quick Start for Live Prototype

### Prerequisites
- Node.js 18+ installed
- MongoDB Atlas account with cluster
- Your MongoDB connection string

### 1. Environment Setup

#### Option A: Automated Setup (Recommended)
```powershell
# Run the production setup script
.\setup-production.ps1
```

#### Option B: Manual Setup
1. Copy the production environment template:
   ```bash
   copy env.production .env
   ```

2. Edit `.env` file and update these values:
   ```env
   # Replace with your actual MongoDB password
   MONGODB_URI=mongodb+srv://shedcodes:YOUR_ACTUAL_PASSWORD@cluster1.l5p3lpp.mongodb.net/napasa?retryWrites=true&w=majority&appName=Cluster1
   
   # Generate a secure JWT secret
   JWT_SECRET=your-super-secure-jwt-secret-here
   
   # Update with your production domain
   CLIENT_URL=https://your-domain.com
   ```

### 2. Install Dependencies
```bash
npm install
```

### 3. Test MongoDB Connection
```bash
# Test connection
node -e "require('dotenv').config(); const mongoose = require('mongoose'); mongoose.connect(process.env.MONGODB_URI).then(() => console.log('✅ Connected')).catch(console.error);"
```

### 4. Start the Server

#### Development Mode
```bash
npm run dev
```

#### Production Mode
```bash
npm start
```

### 5. Verify Installation

#### Health Check
```bash
curl http://localhost:5000/health
```

#### API Endpoints
- **Authentication**: `POST /api/auth/register`, `POST /api/auth/login`
- **Parks**: `GET /api/parks`
- **Tours**: `GET /api/tours`
- **Users**: `GET /api/users` (requires authentication)

## 🔧 Configuration Details

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PORT` | Server port | `5000` |
| `NODE_ENV` | Environment mode | `production` |
| `MONGODB_URI` | MongoDB connection string | `mongodb+srv://...` |
| `JWT_SECRET` | JWT signing secret | `your-secret-key` |
| `JWT_EXPIRE` | JWT expiration time | `7d` |
| `CLIENT_URL` | Allowed CORS origins | `https://your-domain.com` |
| `MAX_FILE_SIZE` | Max upload size in bytes | `10485760` (10MB) |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `50` |

### Security Features

- **Helmet.js**: Security headers
- **CORS**: Cross-origin resource sharing
- **Rate Limiting**: API request throttling
- **JWT Authentication**: Secure token-based auth
- **Input Validation**: Request data validation
- **Password Hashing**: bcrypt encryption

### Database Models

- **Users**: Tourists, Travel Agencies, Lodge Owners, Admins
- **Parks**: National park information
- **Tours**: Safari tour packages
- **Bookings**: Tour reservations
- **Reviews**: User reviews and ratings
- **Lodges**: Accommodation information

## 📱 Flutter App Integration

### Update API Base URL
In your Flutter app, update `lib/core/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:5000/api';  // Development
static const String baseUrlProduction = 'https://your-api-domain.com/api';  // Production
```

### Test API Connection
```dart
// Test connection
final isConnected = await ApiService.healthCheck();
print('API Connected: $isConnected');
```

## 🚀 Deployment Options

### Option 1: Local Development
- Run `npm run dev` for development
- Access at `http://localhost:5000`

### Option 2: Cloud Deployment
- **Heroku**: Easy deployment with MongoDB Atlas
- **Railway**: Modern deployment platform
- **DigitalOcean**: VPS deployment
- **AWS**: EC2 with MongoDB Atlas

### Option 3: Docker Deployment
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

## 🔍 Monitoring & Logs

### Health Monitoring
- Health check endpoint: `/health`
- Database connection status
- Memory usage monitoring

### Logging
- Request logging with Morgan
- Error logging to files
- Production log level: `info`

### Performance
- Response compression
- Connection pooling
- Rate limiting
- Caching headers

## 🛠️ Troubleshooting

### Common Issues

1. **MongoDB Connection Failed**
   - Check your connection string
   - Verify network access in MongoDB Atlas
   - Ensure IP whitelist includes your server

2. **JWT Token Issues**
   - Verify JWT_SECRET is set
   - Check token expiration
   - Ensure proper token format

3. **CORS Errors**
   - Update CLIENT_URL in .env
   - Check frontend domain configuration

4. **Rate Limiting**
   - Adjust RATE_LIMIT_MAX_REQUESTS
   - Check RATE_LIMIT_WINDOW_MS

### Debug Mode
```bash
# Enable debug logging
DEBUG=* npm start
```

## 📊 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update profile
- `POST /api/auth/logout` - User logout

### Park Endpoints
- `GET /api/parks` - List all parks
- `GET /api/parks/:id` - Get park details
- `GET /api/parks/location/:location` - Parks by location
- `GET /api/parks/nearby` - Nearby parks

### Tour Endpoints
- `GET /api/tours` - List all tours
- `GET /api/tours/:id` - Get tour details
- `GET /api/tours/park/:parkId` - Tours by park
- `GET /api/tours/agency/:agencyId` - Tours by agency

## 🎯 Next Steps

1. **Set up your .env file** with your MongoDB credentials
2. **Run the setup script** or configure manually
3. **Test the API endpoints** using Postman or curl
4. **Update your Flutter app** to use the new API
5. **Deploy to production** when ready

## 📞 Support

If you encounter any issues:
1. Check the logs in the `logs/` directory
2. Verify your environment variables
3. Test MongoDB connection separately
4. Check network connectivity

---

**Ready to go live?** 🚀

Run `.\setup-production.ps1` and follow the prompts!
