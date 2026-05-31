FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src ./src
COPY tsconfig.json ./

# Build
RUN npm run build

# Expose port
EXPOSE 3000

# Start server
CMD ["npm", "start"]
