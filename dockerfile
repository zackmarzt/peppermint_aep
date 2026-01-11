FROM oven/bun:1 AS base
WORKDIR /app

# Instala dependências do sistema
RUN apt-get update && apt-get install -y openssl

# --- Estágio de Dependências ---
FROM base AS deps
# Copia arquivos de configuração do workspace
COPY package.json bun.lock turbo.json ./

# Copia package.json dos apps
COPY apps/api/package.json ./apps/api/package.json
COPY apps/client/package.json ./apps/client/package.json
COPY apps/docs/package.json ./apps/docs/package.json
COPY apps/landing/package.json ./apps/landing/package.json
COPY packages ./packages

# Copia o schema do Prisma
COPY apps/api/src/prisma ./apps/api/src/prisma

# Instala todas as dependências
RUN bun install --frozen-lockfile

# --- Estágio de Build ---
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=deps /app/apps/client/node_modules ./apps/client/node_modules
COPY . .

# Regenera o Prisma Client (CORREÇÃO: nome do script corrigido para 'generate')
WORKDIR /app/apps/api
RUN bun run generate

# Build do Next.js (Client)
WORKDIR /app/apps/client
ENV NEXT_TELEMETRY_DISABLED=1
ENV TSC_COMPILE_ON_ERROR=true
ENV ESLINT_NO_DEV_ERRORS=true
RUN bun run build

# Build da API
WORKDIR /app/apps/api
RUN bun run build

# --- Estágio Final (Runner) ---
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN bun add -g pm2

# Copia Client
COPY --from=builder /app/apps/client/.next/standalone ./
COPY --from=builder /app/apps/client/.next/static ./apps/client/.next/static
COPY --from=builder /app/apps/client/public ./apps/client/public

# Copia API
COPY --from=builder /app/apps/api/dist ./apps/api/dist
COPY --from=builder /app/apps/api/package.json ./apps/api/package.json
COPY --from=builder /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=builder /app/apps/api/src/prisma ./apps/api/src/prisma

# Copia Config
COPY ecosystem.config.js .

EXPOSE 3000 5003

CMD ["pm2-runtime", "start", "ecosystem.config.js"]
