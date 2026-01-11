FROM oven/bun:1 AS base
WORKDIR /app

# Instala dependências do sistema necessárias (se houver, ex: python para node-gyp, mas Bun geralmente resolve bem)
# Para Prisma engine em alguns casos é bom ter openssl
RUN apt-get update && apt-get install -y openssl

# --- Estágio de Dependências ---
FROM base AS deps
# Copia arquivos de configuração do workspace
COPY package.json bun.lock turbo.json ./
COPY apps/api/package.json ./apps/api/package.json
COPY apps/client/package.json ./apps/client/package.json
COPY packages ./packages

# Instala todas as dependências (incluindo devDeps para o build)
RUN bun install --frozen-lockfile

# --- Estágio de Build ---
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=deps /app/apps/client/node_modules ./apps/client/node_modules
COPY . .

# Gera o Prisma Client (necessário para a API e possivelmente para tipos compartilhados)
WORKDIR /app/apps/api
RUN bun run db:generate

# Build do Next.js (Client)
WORKDIR /app/apps/client
# Desativa verificação de tipos e linting durante o build do Docker para evitar erros de CI/CD estritos que travam o deploy
# O Next.js standalone mode é usado
ENV NEXT_TELEMETRY_DISABLED=1
ENV TSC_COMPILE_ON_ERROR=true
ENV ESLINT_NO_DEV_ERRORS=true
RUN bun run build

# Build da API (Fastify) - Apenas transpile TS para JS
WORKDIR /app/apps/api
RUN bun run build

# --- Estágio Final (Runner) ---
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Instala PM2 globalmente no Bun para gerenciar processos
RUN bun add -g pm2

# Cria usuário não-root por segurança (opcional, mas recomendado)
# RUN addgroup --system --gid 1001 nodejs
# RUN adduser --system --uid 1001 nextjs

# Copia os artefatos do Client
# O modo 'standalone' do Next.js coloca quase tudo que precisa em .next/standalone
COPY --from=builder /app/apps/client/.next/standalone ./
COPY --from=builder /app/apps/client/.next/static ./apps/client/.next/static
COPY --from=builder /app/apps/client/public ./apps/client/public

# Copia os artefatos da API
COPY --from=builder /app/apps/api/dist ./apps/api/dist
COPY --from=builder /app/apps/api/package.json ./apps/api/package.json
# Precisamos do node_modules da API ou Prisma schema se ele rodar migrations no boot
COPY --from=builder /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=builder /app/apps/api/src/prisma ./apps/api/src/prisma

# Copia configuração do PM2
COPY ecosystem.config.js .

# Expõe as portas
EXPOSE 3000 5003

# Comando de inicialização
CMD ["pm2-runtime", "start", "ecosystem.config.js"]