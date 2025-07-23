# ⚠️ **WIP**  Quickstart for Azure Landing Zone Container Deployments ⚠️ **DRAFT**


A secure, compliant infrastructure template for deploying containerized applications to Azure Landing Zone environments. This template follows all Azure Landing Zone security guardrails and best practices for B.C. government cloud deployments.


## Prerequisites
- BCGOV Azure account with appropriate permissions , [Registry link](https://registry.developer.gov.bc.ca/)
- Azure CLI
- GH CLI
- Docker/Podman installed (for local development with containers)
- Terraform CLI and Terragrunt (for infrastructure deployment)

# Folder Structure
```
/quickstart-azure-containers
├── .github/                   # GitHub workflows and actions for CI/CD
│   └── workflows/             # GitHub Actions workflow definitions
├── infrastructure/            # Terraform code for Azure infrastructure components
│   ├── main.tf                # Root Terraform configuration
│   ├── provider.tf            # Provider configuration (Azure, etc.)
│   ├── variables.tf           # Global variables
│   ├── outputs.tf             # Global outputs
│   └── modules/               # Reusable Terraform modules
│       ├── backend/           # App Service, Container Apps, or AKS backend infrastructure
│       ├── frontend/          # Frontend hosting (e.g., Static Web Apps, App Service)
│       ├── postgresdb/        # PostgreSQL database instance and configuration
│       ├── flyway/            # Flyway migration runner setup
│       ├── networking/        # Virtual network, subnets, and network security
│       ├── monitoring/        # Azure Monitor, Log Analytics, and alerting
│       └── frontdoor/         # Azure Front Door 
├── backend/                   # NestJS backend API code
│   ├── src/                   # Source code with controllers, services, and modules
│   ├── prisma/                # Prisma ORM schema and migrations
│   └── Dockerfile             # Container definition for backend service
├── frontend/                  # Vite + React SPA
│   ├── src/                   # React components, routes, and services
│   ├── e2e/                   # End-to-end tests using Playwright
│   └── Dockerfile             # Container definition for frontend service
├── migrations/                # Flyway migrations for database schema management
│   └── sql/                   # SQL migration scripts
├── terragrunt/                # Terragrunt configuration files for managing Terraform modules
├── docker-compose.yml         # Local development environment definition
├── README.md                  # Project documentation
├── initial-azure-setup.sh     # Shell script to automate initial setup to do CI/CD from GHA.
└── package.json               # Node.js monorepo for shared configurations
```

