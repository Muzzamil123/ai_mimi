# syntax=docker/dockerfile:1
# Production image for the React frontend: build the static bundle with Node,
# then serve it with nginx. Build context is the repository root.
#
# The API base URL is baked at build time (Vite inlines VITE_* env). Default is
# the same-origin "/api/v1" so nginx can reverse-proxy the API and avoid CORS;
# override with a build-arg to point at a separate API host.
FROM node:20-bookworm-slim AS build
WORKDIR /app

ARG VITE_API_BASE_URL="/api/v1"
ARG VITE_APP_NAME="AI Character Video Platform"
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL \
    VITE_APP_NAME=$VITE_APP_NAME

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM nginx:1.27-alpine AS runtime
COPY infrastructure/docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=10s --timeout=5s --retries=6 \
  CMD wget -qO- http://localhost/healthz >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
