# Build
FROM node:24.11.1-slim AS build

# Prisma requires OpenSSL/libssl detection during generate/build.
RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends openssl libssl3 ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Copy, build static files; see .dockerignore for exclusions
WORKDIR /app
COPY . ./
ENV PRISMA_CLI_BINARY_TARGETS=debian-openssl-3.0.x
RUN npm run deploy

# Dependencies
FROM node:24.11.1-slim AS dependencies

# Prisma (and some native deps) expect OpenSSL/libssl present.
RUN apt-get update -y \
	&& apt-get install -y --no-install-recommends openssl libssl3 ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Copy, build static files; see .dockerignore for exclusions
WORKDIR /app
COPY . ./
ENV PRISMA_CLI_BINARY_TARGETS=debian-openssl-3.0.x
RUN npm ci --ignore-scripts --no-update-notifier --omit=dev

# Deploy using minimal Distroless image
FROM node:24.11.1
ENV NODE_ENV=production

# Copy app and dependencies
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/prisma ./node_modules/prisma
COPY --from=build /app/dist ./dist

EXPOSE 3001
HEALTHCHECK --start-period=2s --start-interval=5s --interval=30s --timeout=3s CMD curl -f http://localhost:30001/api


CMD ["--max-old-space-size=150", "/app/dist/main"]
