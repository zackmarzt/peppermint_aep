# Peppermint Ticket Management

## Project Overview
Peppermint is a Ticket Management System designed for helpdesks and service desks to manage internal staff and customer requests. It is a monorepo structured project using Turborepo, featuring a Fastify backend and a Next.js frontend.

## Architecture & Tech Stack

**Runtime:** Bun (preferred over Node.js/Yarn)

**Monorepo Management:** Turborepo

### 🟢 Backend (`apps/api`)
*   **Framework:** Fastify
*   **Language:** TypeScript
*   **Database:** PostgreSQL (via Docker)
*   **ORM:** Prisma
*   **Authentication:** JWT, Session, SAML, OAuth2 (Google)
*   **Key Libraries:** `nodemailer` (Email), `pino` (Logging), `posthog-node` (Analytics)
*   **Entry Point:** `src/main.ts`

### 🔵 Frontend (`apps/client`)
*   **Framework:** Next.js (Pages Router)
*   **Language:** TypeScript
*   **Styling:** Tailwind CSS, Shadcn UI (`@radix-ui/*`)
*   **State Management:** React Query (v3)
*   **Editor:** BlockNote
*   **Internationalization:** `next-translate`
*   **Key Locations:**
    *   `pages/`: Application routes/views.
    *   `components/`: Reusable UI components.
    *   `lib/`: Utility functions.

### 🟡 Other Apps
*   **`apps/docs`**: Documentation (likely Nextra).
*   **`apps/landing`**: Landing page (Next.js App Router).

## Getting Started

### Prerequisites
*   **Bun**: The project uses Bun as the package manager and runtime.
*   **Docker & Docker Compose**: Required for the database and other services.

### Installation
```bash
bun install
```

### Environment Setup
1.  Ensure Docker is running.
2.  Set up environment variables by copying `.env.example` files to `.env` in respective apps (`apps/api`, `apps/client`).

### Database Setup
Start the Postgres container:
```bash
docker-compose up -d peppermint_postgres
```

Run Prisma migrations (from `apps/api`):
```bash
cd apps/api
bun run db:migrate
bun run generate
```

### Running the Project
Start all applications in development mode:
```bash
bun dev
```
(This runs `turbo run dev --parallel`)

### Building
Build all applications:
```bash
bun run build
```

## Development Conventions

*   **Monorepo:** Code is organized into `apps` (deployables) and `packages` (shared config).
*   **TypeScript:** Strict TypeScript is used across the codebase.
*   **Prisma:** Schema changes should be made in `apps/api/src/prisma/schema.prisma` followed by `bun run db:migrate`.
*   **Fastify:** The API follows a pattern of Routes -> Controllers -> Services/Prisma.
*   **Styling:** Use Tailwind CSS utility classes and Shadcn UI components for consistency.
*   **Commits:** Follow standard git commit message conventions (e.g., `feat:`, `fix:`, `chore:`).
