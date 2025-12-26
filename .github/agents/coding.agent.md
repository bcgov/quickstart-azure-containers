---
description: Guidelines for coding on the BC Government Azure quickstart template project
name: Coding Agent
tools: ['vscode', 'execute', 'read/problems', 'read/readFile', 'read/terminalSelection', 'read/terminalLastCommand', 'edit', 'search', 'web', 'azure-mcp/*', 'github/*', 'upstash/context7/*', 'azure-server/search', 'todo']
---

# Coding Guidelines

This custom agent provides coding standards and practices for automated agents and contributors working on this BC Government Azure quickstart template.

## Code Style and Standards

### General Guidelines
- **Indentation**: Use 2 spaces consistently (not tabs)
- **ESLint/Prettier**: Follow existing ESLint and Prettier configuration
- **Testing**: Use the AAA (Arrange-Act-Assert) pattern for unit tests
- **Functions**: Prefer small, testable functions with focused responsibility
- **Input Validation**: Always validate inputs on public endpoints
- **Error Handling**: Preserve and enhance existing error handling patterns

### Security and Compliance
- **Secrets**: Never add secrets, credentials, or sensitive data to the repository
- **SECURITY.md**: Review and follow guidance in SECURITY.md before making changes
- **BC Gov Compliance**: Ensure all changes meet BC Gov compliance expectations
- **Code Review**: Check `.github/instructions/` for any specific change guidelines

## Backend Development (NestJS + Prisma)

### Project Structure
- **Entry point**: `backend/src/main.ts` - initializes telemetry before booting Nest
- **Global prefix**: `/api` (e.g., root GET is `/api`)
- **API Versioning**: URI versioning with prefix `v` (example: `/api/v1/users`)
- **Security**: helmet middleware, CORS enabled, trust proxy enabled

### Controllers and Routes
- **Health**: `GET /api/health` (from health.controller.ts)
- **Metrics**: `GET /api/metrics` (Prometheus registry from metrics.controller.ts)
- **Prometheus Middleware**: `GET /prom-metrics` (NOT under /api, registered as Express middleware)
- All controller routes must be under `/api` prefix

### Database Integration
- **Schema File**: `backend/prisma/schema.prisma`
- **Usage**: Prisma is ONLY used as ORM, NOT for schema migrations
- **Default Schema**: `app` schema
- **Connection Config**: `backend/src/prisma.service.ts` uses environment variables:
  - `POSTGRES_HOST` (default: localhost)
  - `POSTGRES_PORT` (default: 5432)
  - `POSTGRES_USER` (default: postgres)
  - `POSTGRES_PASSWORD` (default: default)
  - `POSTGRES_DATABASE` (default: postgres)
  - `POSTGRES_SCHEMA` (default: app)

### Observability (Azure Monitor)
- **Telemetry File**: `backend/src/telemetry.ts`
- **Enable**: Set `APPLICATIONINSIGHTS_CONNECTION_STRING` environment variable
- **Fallback**: If unset, app runs without telemetry

### Useful Commands
From `backend/` directory:
```bash
npm run start:dev      # Start development server
npm run lint           # Run ESLint
npm test               # Run unit tests
npm run test:e2e       # Run e2e tests
npm run test:cov       # Run tests with coverage
```

## Frontend Development (React + Vite)

### Project Structure
- **File-based Routing**: Routes defined in `frontend/src/routes/`
- **Route Tree**: Auto-generated in `frontend/src/routeTree.gen.ts`
- **Components**: Located in `frontend/src/components/`
- **Design System**: Uses BC Gov Design System React components and BC Sans font

### Backend Connectivity

#### Development (Vite Dev Server)
- **Env Variable**: `VITE_API_BASE_URL`
- **Usage**: Used by Vite proxy (frontend/vite.config.ts) and Axios client
- **Default**: If unset, frontend uses `/api` and relies on Vite proxy

#### Production (Caddy Reverse Proxy)
- **Env Variable**: `VITE_BACKEND_URL`
- **Usage**: Used in `frontend/Caddyfile` to reverse-proxy `/api*` requests to backend

### Useful Commands
From `frontend/` directory:
```bash
npm run dev            # Start Vite dev server
npm run build          # Build for production
npm run lint           # Run ESLint
npm run test:unit      # Run unit tests
npm run test:cov       # Run tests with coverage
npx playwright test    # Run e2e tests
```

## Migrations (Flyway)

### SQL Migrations
- **Location**: `migrations/sql/`
- **Execution**: docker-compose migrations service runs Flyway against Postgres
- **Manual Execution**: `docker-compose exec migrations flyway migrate`
- **Naming**: Follow Flyway versioning convention (e.g., V1.0.0__description.sql)

## Infrastructure as Code (Terraform)

### File Organization
- **Root Modules**: Code in `infra/` with reusable modules in `infra/modules/`
- **Structure Rule**: Never put locals, data, or provider blocks in main.tf
- **Separate Files**: Use individual files for locals, data sources, and provider configurations
- **Follow Patterns**: Use existing module boundaries and patterns

### Azure Landing Zone Constraints

#### ❌ Do NOT
- Modify VNet DNS settings or address space
- Create ExpressRoute, VPN, Route Tables, or VNet peering
- Delete Diagnostics Settings marked as `setbypolicy`
- Use Basic/Standard ACR SKU with private endpoints (Premium required)

#### ✅ Do
- Create NSG BEFORE creating subnets (policy requirement)
- Use Private Endpoints for all PaaS services
- Set subnets as Private Subnets (Zero Trust architecture)
- Use existing VNet provided by platform team

#### External Documentation
Treat the Azure Landing Zone docs in the bcgov/public-cloud-techdocs repo as authoritative:
- [Networking Design](https://raw.githubusercontent.com/bcgov/public-cloud-techdocs/refs/heads/main/docs/azure/design-build-deploy/networking.md)
- [Next Steps](https://raw.githubusercontent.com/bcgov/public-cloud-techdocs/refs/heads/main/docs/azure/design-build-deploy/next-steps.md)
- [User Management](https://github.com/bcgov/public-cloud-techdocs/blob/main/docs/azure/design-build-deploy/user-management.md)

## Local Development with Docker Compose

### Stack Overview
- **File**: `docker-compose.yml`
- **Services**: Postgres + migrations + app containers
- **Migrations**: Automatically run during compose startup

### Running Locally
```bash
docker-compose up      # Start entire stack
docker-compose down    # Stop and remove containers
docker-compose logs -f # Follow logs
```

## Common Pitfalls

### API Routes
- **Controller Routes**: Automatically under `/api` prefix
- **Middleware Routes**: Registered separately (e.g., `/prom-metrics` is NOT under `/api`)

### Frontend Environment Variables
- **Development**: Use `VITE_API_BASE_URL` for Vite proxy and Axios
- **Production**: Use `VITE_BACKEND_URL` for Caddy reverse proxy
- **Don't Mix**: Ensure correct variable is used for the runtime context

### Database
- **Prisma**: Used ONLY as ORM; never use it for migrations
- **Flyway**: Handles all schema migrations
- **Keep Separate**: Schema changes must go through Flyway, not Prisma migrations

## Testing Best Practices

### Unit Tests
- **Pattern**: Arrange-Act-Assert (AAA)
- **Location**: Tests collocated with source files (*.spec.ts)
- **Framework**: Vitest for backend and frontend

### E2E Tests
- **Backend**: `backend/test/app.e2e-spec.ts`
- **Frontend**: `frontend/e2e/` using Playwright
- **Command**: `npx playwright test` from frontend directory

### Coverage
- Run `npm run test:cov` in both backend and frontend
- Aim for meaningful coverage of critical paths
- Focus on behavior, not line coverage metrics

## Before Making Changes

1. **Read SECURITY.md**: Understand security implications
2. **Check Instructions**: Look in `.github/instructions/` for specific guidance
3. **Follow Patterns**: Use existing code as reference for style and structure
4. **Plan Tests**: Consider test cases during implementation
5. **Validate Inputs**: Especially on public API endpoints
6. **Preserve Errors**: Keep existing error handling, enhance as needed

## Useful References

- See [SECURITY.md](../../SECURITY.md) for security guidelines
- See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution process
