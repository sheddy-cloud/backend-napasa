# NAPASA Backend API

A comprehensive Node.js backend API for the NAPASA Tanzania Tourism application, built with Express.js and MongoDB.

## 🚀 Features

- **User Authentication & Authorization** - JWT-based authentication with role-based access control
- **Tourism Management** - Complete CRUD operations for parks, tours, lodges, and bookings
- **Review System** - User reviews and ratings for tours and accommodations
- **Travel Agency Management** - Agency profiles and tour management
- **Booking System** - Complete booking lifecycle management
- **File Upload Support** - Image and document upload capabilities
- **Rate Limiting** - API rate limiting for security
- **Data Validation** - Comprehensive input validation and sanitization

## 🛠️ Tech Stack

- **Runtime**: Node.js (v18+)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **Security**: Helmet, CORS, Rate Limiting
- **Validation**: Express Validator
- **File Upload**: Multer

## 📋 Prerequisites

- Node.js (v18 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn

## 🚀 Quick Start

### 1. Clone and Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Setup

Copy the example environment file and configure your variables:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```env
# Server Configuration
PORT=5000
NODE_ENV=development

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/napasa

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRE=7d

# CORS Configuration
CLIENT_URL=http://localhost:3000
```

### 3. Start the Server

**Development mode:**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:5000`

## 📚 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|---------|
| POST | `/auth/register` | Register new user | Public |
| POST | `/auth/login` | User login | Public |
| POST | `/auth/logout` | User logout | Private |
| GET | `/auth/me` | Get current user | Private |
| PUT | `/auth/profile` | Update user profile | Private |
| PUT | `/auth/change-password` | Change password | Private |

### Parks Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|---------|
| GET | `/parks` | Get all parks | Public |
| GET | `/parks/:id` | Get park by ID | Public |
| POST | `/parks` | Create new park | Admin |
| PUT | `/parks/:id` | Update park | Admin |
| DELETE | `/parks/:id` | Delete park | Admin |
| GET | `/parks/location/:location` | Get parks by location | Public |
| GET | `/parks/nearby` | Get nearby parks | Public |

### Tours Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|---------|
| GET | `/tours` | Get all tours | Public |
| GET | `/tours/:id` | Get tour by ID | Public |
| POST | `/tours` | Create new tour | Travel Agency |
| PUT | `/tours/:id` | Update tour | Travel Agency |
| GET | `/tours/park/:parkId` | Get tours by park | Public |
| GET | `/tours/agency/:agencyId` | Get tours by agency | Public |

### Booking Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|---------|
| POST | `/bookings` | Create new booking | Private |
| GET | `/bookings` | Get user bookings | Private |
| GET | `/bookings/:id` | Get booking by ID | Private |
| PUT | `/bookings/:id/cancel` | Cancel booking | Private |

### Review Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|---------|
| POST | `/reviews` | Create new review | Private |
| GET | `/reviews/tour/:tourId` | Get tour reviews | Public |
| GET | `/reviews` | Get user reviews | Private |
| PUT | `/reviews/:id/helpful` | Mark review as helpful | Private |

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## 👥 User Roles

- **Tourist** - Can book tours, write reviews, manage profile
- **Travel Agency** - Can create and manage tours
- **Lodge Owner** - Can manage lodge information
- **Admin** - Full system access

## 📊 Database Models

### User Model
- Basic user information (name, email, phone, role)
- Role-specific additional data
- Authentication fields

### Park Model
- Park information (name, location, description)
- Wildlife and facilities
- Coordinates and ratings

### Tour Model
- Tour details (title, description, duration, price)
- Itinerary and requirements
- Availability and ratings

### Booking Model
- Booking information (participants, dates, price)
- Payment and status tracking
- Emergency contact details

### Review Model
- Review content (rating, title, comment)
- Pros and cons
- Helpful votes and responses

## 🛡️ Security Features

- **Helmet** - Security headers
- **CORS** - Cross-origin resource sharing
- **Rate Limiting** - API request limiting
- **Input Validation** - Request data validation
- **Password Hashing** - bcrypt password encryption
- **JWT Security** - Secure token handling

## 🧪 Testing

Run tests with:

```bash
npm test
```

## 📝 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 5000 |
| `NODE_ENV` | Environment | development |
| `MONGODB_URI` | MongoDB connection string | mongodb://localhost:27017/napasa |
| `JWT_SECRET` | JWT secret key | - |
| `JWT_EXPIRE` | JWT expiration time | 7d |
| `CLIENT_URL` | Frontend URL for CORS | http://localhost:3000 |

## 🚀 Deployment

### Production Checklist

1. Set `NODE_ENV=production`
2. Use a strong `JWT_SECRET`
3. Configure production MongoDB URI
4. Set up proper CORS origins
5. Enable HTTPS
6. Set up monitoring and logging

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

## 📞 Support

For support and questions, please contact the development team.

## 📄 License

This project is licensed under the MIT License.
