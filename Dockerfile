# Use Node 18 Alpine
FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./

# Install ALL dependencies including devDependencies
RUN npm install

COPY . .

RUN mkdir -p uploads

ENV NODE_ENV=development \
    HOST=0.0.0.0 \
    PORT=5000

EXPOSE 5000

CMD ["npm", "run", "dev"]
