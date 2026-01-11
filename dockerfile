FROM oven/bun:1 AS base
WORKDIR /app

# Instala dependências do sistema necessárias
RUN apt-get update && apt-get install -y openssl

# --- Estágio de Dependências ---
FROM base AS deps
# Copia arquivos de configuração do workspace
COPY package.json bun.lock turbo.json ./

# Copia TODOS os package.json dos apps/workspaces para garantir que o 'bun install' funcione
COPY apps/api/package.json ./apps/api/package.json
COPY apps/client/package.json ./apps/client/package.json
# É necessário copiar os package.json de todos os workspaces definidos no root, mesmo que não os usemos
COPY apps/docs/package.json ./apps/docs/package.json
COPY apps/landing/package.json ./apps/landing/package.json
COPY packages ./packages

# Instala todas as dependências
RUN bun install --frozen-lockfile

# --- Estágio de Build ---
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=deps /app/apps/client/node_modules ./apps/client/node_modules
COPY . .

# Gera o Prisma Client
WORKDIR /app/apps/api
RUN bun run db:generate

# Build do Next.js (Client)
WORKDIR /app/apps/client
ENV NEXT_TELEMETRY_DISABLED=1
ENV TSC_COMPILE_ON_ERROR=true
ENV ESLINT_NO_DEV_ERRORS=true
# O next build geralmente requer que as dependências estejam linkadas corretamente
RUN bun run build

# Build da API (Fastify)
WORKDIR /app/apps/api
RUN bun run build

# --- Estágio Final (Runner) ---
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN bun add -g pm2

# Copia os artefatos do Client
COPY --from=builder /app/apps/client/.next/standalone ./
COPY --from=builder /app/apps/client/.next/static ./apps/client/.next/static
COPY --from=builder /app/apps/client/public ./apps/client/public

# Copia os artefatos da API
COPY --from=builder /app/apps/api/dist ./apps/api/dist
COPY --from=builder /app/apps/api/package.json ./apps/api/package.json
COPY --from=builder /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=builder /app/apps/api/src/prisma ./apps/api/src/prisma

# Copia configuração do PM2
COPY ecosystem.config.js .

EXPOSE 3000 5003

CMD ["pm2-runtime", "start", "ecosystem.config.js"]
