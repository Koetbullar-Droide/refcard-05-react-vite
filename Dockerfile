# --- Stage 1: Build ---
FROM node:24-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
ARG VITE_API_BASE_URL
ARG VITE_IMGS=items
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_IMGS=$VITE_IMGS
RUN npm run build

# --- Stage 2: Runtime ---
FROM nginx:1.27-alpine
# Version aus dem Git-Tag (setzt die Pipeline): /version.json + Image-Label
ARG APP_VERSION=dev
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.version=$APP_VERSION \
      org.opencontainers.image.revision=$GIT_SHA \
      org.opencontainers.image.source=https://github.com/Koetbullar-Droide/refcard-05-react-vite
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN printf '{"name":"biztrips-frontend","version":"%s","commit":"%s"}\n' "$APP_VERSION" "$GIT_SHA" \
      > /usr/share/nginx/html/version.json
EXPOSE 80
