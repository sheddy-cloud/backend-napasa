# syntax=docker/dockerfile:1

# Use Node 18 LTS Alpine for smaller image
FROM node:18-alpine AS base

WORKDIR /usr/src/app

# Install dependencies separately for better layer caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application source
COPY . .

# Ensure uploads directory exists at runtime
RUN mkdir -p uploads

# Set environment
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=5000

# Expose app port
EXPOSE 5000

# Start the server
CMD ["node", "server.js"]







