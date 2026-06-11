# ── Stage 1: install production dependencies ──────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force

# ── Stage 2: production image ─────────────────────────────────────────────
FROM node:20-alpine AS production
WORKDIR /app

RUN addgroup -S qcart && adduser -S qcart -G qcart

COPY --from=deps --chown=qcart:qcart /app/node_modules ./node_modules
COPY --chown=qcart:qcart src ./src
COPY --chown=qcart:qcart scripts ./scripts
COPY --chown=qcart:qcart package.json ./

USER qcart

ENV NODE_ENV=production

# PORT is injected at runtime by the hosting platform (Render: 10000, local: 3000)
EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://localhost:${PORT:-3000}/v1/health || exit 1

CMD ["sh", "-c", "node scripts/migrate.js && node src/server.js"]
