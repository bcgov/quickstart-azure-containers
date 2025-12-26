---
description: Guidelines for code review on the BC Government Azure quickstart template project
name: Review Agent
tools: ['vscode', 'execute', 'read/problems', 'read/readFile', 'read/terminalSelection', 'read/terminalLastCommand', 'edit', 'search', 'web', 'azure-mcp/*', 'github/*', 'upstash/context7/*', 'azure-server/search', 'todo']
---

# Review Guidelines

These guidelines define what to look for when reviewing changes in this repository. They complement the coding standards in [.github/agents/coding.agent.md](./coding.agent.md).

## Review Principles

- Prefer small, focused diffs.
- Preserve existing behavior unless the change explicitly intends to modify it.
- Require tests for behavior changes.
- Reject changes that introduce secrets, weaken security posture, or violate platform constraints.

## PR Hygiene Checklist

- **Scope**: PR title and description match the diff; no unrelated refactors.
- **Docs**: README/docs updated if behavior, config, or deployment steps changed.
- **Changelog/notes**: Breaking changes and migrations are clearly called out.
- **No secrets**: No credentials, keys, tokens, connection strings, or sensitive IDs committed (also check `.env*`, workflow files, and sample configs).
- **Formatting**: Follows ESLint/Prettier conventions already in the repo.

## Security & Compliance Review

- Validate all public inputs (request params/body/query) and ensure safe defaults.
- Ensure error responses do not leak sensitive details (stack traces, internal URLs, SQL details).
- Confirm headers/middleware patterns remain intact (helmet, CORS, trust proxy) when backend changes touch app bootstrap.
- Verify dependency updates are minimal and justified; watch for supply-chain risk.
- Follow guidance in [SECURITY.md](../../SECURITY.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Backend Review (NestJS + Prisma)

Reference: [.github/agents/coding.agent.md](./coding.agent.md)

### Routing & API conventions
- All controller routes must remain under global `/api` prefix.
- Do not accidentally place middleware-only routes under `/api` (example pitfall: `/prom-metrics` is **not** under `/api`).

### Error handling & logging
- Preserve existing error handling patterns; improvements should add context without leaking secrets.
- Avoid noisy logs in hot paths; ensure logs are actionable.

### Data access (Prisma)
- Prisma is used **only** as ORM. Schema changes must go through Flyway (see “Database & Migrations Review”).
- Ensure Prisma queries are bounded (pagination/limits), avoid N+1 patterns where possible.

### Backend test expectations
From `backend/` directory (as applicable):
- `npm run lint`
- `npm test`
- `npm run test:e2e` (when endpoints or app wiring change)
- `npm run test:cov` (when changing core logic)

## Frontend Review (React + Vite)

Reference: [.github/agents/coding.agent.md](./coding.agent.md)

### Environment variables (common pitfall)
- **Development**: `VITE_API_BASE_URL` (Vite proxy + Axios client usage)
- **Production**: `VITE_BACKEND_URL` (Caddy reverse proxy)
- Do not mix these; verify changes in runtime wiring match the intended environment.

### Routing & generated files
- Routes live in `frontend/src/routes/`.
- `frontend/src/routeTree.gen.ts` is generated; review changes there cautiously and prefer reviewing the source route changes.

### Frontend test expectations
From `frontend/` directory (as applicable):
- `npm run lint`
- `npm run test:unit`
- `npm run test:cov`
- `npx playwright test` (when UX flows/routing/integration behavior changes)

## Database & Migrations Review (Flyway)

Reference: [.github/agents/coding.agent.md](./coding.agent.md)

- All schema changes must be Flyway SQL migrations under `migrations/sql/`.
- Migration filenames must follow Flyway conventions (e.g., `V1.0.0__description.sql`).
- Prisma migrations must **not** be introduced.
- Ensure migrations are:
  - Idempotent where required by the repo’s patterns
  - Backward-compatible when possible
  - Paired with app changes that can handle old/new schema during rollout (call out if not possible)

## Infrastructure as Code Review (Terraform)

Reference: [.github/agents/coding.agent.md](./coding.agent.md)

### Structure rules
- Root modules under `infra/`, reusable modules under `infra/modules/`.
- Do **not** put `locals`, `data`, or `provider` blocks in `main.tf`; keep them in separate files following existing patterns.

### Azure Landing Zone constraints (must enforce)
Reject PRs that:
- Modify VNet DNS settings or address space
- Create ExpressRoute, VPN, Route Tables, or VNet peering
- Delete Diagnostics Settings marked `setbypolicy`
- Use Basic/Standard ACR SKU with private endpoints (Premium required)

Require PRs that create subnets to:
- Create NSGs **before** subnets (policy requirement)
- Prefer Private Endpoints for PaaS services
- Treat subnets as private subnets (Zero Trust)

## Observability Review

- Backend telemetry should remain optional and safe:
  - If `APPLICATIONINSIGHTS_CONNECTION_STRING` is unset, app must continue to run without telemetry.
- Ensure metrics/health endpoints remain stable if they are depended on by CI/CD or monitoring.

## Common Review Red Flags

- Hard-coded URLs, IDs, or environment-specific values committed into source.
- Changes that alter deployment behavior without updating documentation/workflows.
- Introducing secrets in sample configs or test files.
- Large refactors bundled with functional changes.
- Breaking API route conventions (loss of `/api` prefix or versioning scheme).

## Approval Criteria

Approve when:
- The change is scoped, documented, and tested appropriately.
- Security/compliance posture is preserved or improved.
- Repo conventions in [.github/agents/coding.agent.md](./coding.agent.md) are followed.
- For IaC changes: Landing Zone constraints are respected and AVM checks are satisfied where applicable.