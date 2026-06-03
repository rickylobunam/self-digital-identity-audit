# syntax=docker/dockerfile:1

# ── Build stage ──────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS build

WORKDIR /app

ENV NODE_ENV=development

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src

RUN npm run build


# ── Runtime stage ────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist

EXPOSE 3000

USER node

CMD ["npm", "start"]