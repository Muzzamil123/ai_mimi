# syntax=docker/dockerfile:1
# Development image for the React (Vite) frontend.
# Build context is the repository root.
FROM node:20-bookworm-slim

ENV NODE_ENV=development
WORKDIR /app

# Install dependencies first for better layer caching.
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

# Application code (shadowed by a bind mount in development).
COPY frontend/ ./

EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
