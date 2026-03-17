# ── Stage 1: build ──────────────────────────────────────────────
FROM node:16-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --legacy-peer-deps --silent

COPY . .
RUN node --max_old_space_size=4096 ./node_modules/@angular/cli/bin/ng build --prod

# ── Stage 2: serve ──────────────────────────────────────────────
FROM nginx:stable-alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# envsubst replaces ${APP_BASE_URL} etc. in env.template.js at container start
EXPOSE 80
CMD ["/bin/sh", "-c", \
  "envsubst < /usr/share/nginx/html/assets/env.template.js \
   > /usr/share/nginx/html/assets/env.js && \
   exec nginx -g 'daemon off;'"]
