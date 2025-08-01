# Build
FROM node:22.17.1-slim AS build

# Copy, build static files; see .dockerignore for exclusions
WORKDIR /app
COPY . ./
ENV PRISMA_CLI_BINARY_TARGETS=debian-openssl-3.0.x
RUN npm run deploy

# Dependencies
FROM node:22.17.1-slim AS dependencies

# Copy, build static files; see .dockerignore for exclusions
WORKDIR /app
COPY . ./
ENV PRISMA_CLI_BINARY_TARGETS=debian-openssl-3.0.x
RUN npm ci --ignore-scripts --no-update-notifier --omit=dev

# Deploy using minimal Distroless image
FROM node:22.17.1
ENV NODE_ENV=production

# Copy app and dependencies
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/prisma ./node_modules/prisma
COPY --from=build /app/dist ./dist

# Boilerplate, not used in OpenShift/Kubernetes
EXPOSE 3001
HEALTHCHECK --start-period=2s --start-interval=5s --interval=30s --timeout=3s CMD curl -f http://localhost:30001/api


CMD ["--max-old-space-size=50", "/app/dist/main"]
