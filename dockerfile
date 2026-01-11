FROM oven/bun:1 AS base
WORKDIR /app

# Instala dependências do sistema
RUN apt-get update && apt-get install -y openssl

# --- Estágio de Dependências ---
FROM base AS deps
COPY package.json bun.lock turbo.json ./
COPY apps/api/package.json ./apps/api/package.json
COPY apps/client/package.json ./apps/client/package.json
COPY apps/docs/package.json ./apps/docs/package.json
COPY apps/landing/package.json ./apps/landing/package.json
COPY packages ./packages
COPY apps/api/src/prisma ./apps/api/src/prisma

RUN bun install --frozen-lockfile

# --- Estágio de Build ---
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=deps /app/apps/client/node_modules ./apps/client/node_modules
COPY . .

# Prisma
WORKDIR /app/apps/api
RUN bun run generate

# Client
WORKDIR /app/apps/client
ENV NEXT_TELEMETRY_DISABLED=1
ENV TSC_COMPILE_ON_ERROR=true
ENV ESLINT_NO_DEV_ERRORS=true
RUN bun run build

# API
WORKDIR /app/apps/api
RUN bun run build

# --- Estágio Final (Runner) ---
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN bun add -g pm2

# COPIA NODE_MODULES DA RAIZ (Crucial para monorepo)
COPY --from=builder /app/node_modules ./node_modules

# API: Copia dist e node_modules local
COPY --from=builder /app/apps/api/dist ./apps/api/dist
COPY --from=builder /app/apps/api/package.json ./apps/api/package.json
COPY --from=builder /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=builder /app/apps/api/src/prisma ./apps/api/src/prisma

# CLIENT: Ajusta a cópia do standalone para bater com o cwd: apps/client
# O standalone em monorepo gera a pasta apps/client dentro dele.
# Copiando o conteúdo de .next/standalone para a raiz /app, 
# teremos /app/apps/client/server.js e /app/apps/client/.next/...
COPY --from=builder /app/apps/client/.next/standalone ./
COPY --from=builder /app/apps/client/.next/static ./apps/client/.next/static
COPY --from=builder /app/apps/client/public ./apps/client/public

# Config do PM2
COPY ecosystem.config.js .

EXPOSE 3000 5003

CMD ["pm2-runtime", "start", "ecosystem.config.js"]