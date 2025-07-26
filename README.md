# 🚀 Quickstart for Azure Landing Zone

## ⚠️ 🚧 **WORK IN PROGRESS - DRAFT** 🚧 ⚠️

> **🚨 Important Notice**: This template is currently under active development and should be considered a **DRAFT** version. Features, configurations, and documentation may change without notice. Use in production environments is **not recommended** at this time.


[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Lifecycle:Stable](https://img.shields.io/badge/Lifecycle-Stable-97ca00)](https://github.com/bcgov/repomountie/blob/master/doc/lifecycle-badges.md)

A production-ready, secure, and compliant infrastructure template for deploying containerized applications to Azure Landing Zone environments. This template follows Azure Landing Zone security guardrails and BC Government cloud deployment best practices.

## 🎯 What This Template Provides

- **Full-stack containerized application**: NestJS backend + React/Vite frontend
- **Secure Azure infrastructure**: Landing Zone compliant with proper network isolation
- **Database management**: PostgreSQL with Flyway migrations and optional CloudBeaver admin UI
- **CI/CD pipeline**: GitHub Actions with OIDC authentication
- **Infrastructure as Code**: Terraform with Terragrunt for multi-environment management
- **Monitoring & observability**: Azure Monitor, Application Insights, and comprehensive logging
- **Security best practices**: Managed identities, private endpoints, and network security groups

## 📋 Prerequisites

### Required Tools
- **Azure CLI** v2.50.0+ - [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **GitHub CLI** v2.0.0+ - [Installation Guide](https://cli.github.com/)
- **Terraform** v1.5.0+ - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)
- **Terragrunt** v0.50.0+ - [Installation Guide](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- **Docker** or **Podman** - [Docker Installation](https://docs.docker.com/get-docker/)

### Required Accounts & Permissions
- **BCGOV Azure account** with appropriate permissions - [Registry Link](https://registry.developer.gov.bc.ca/)
- **GitHub repository** with Actions enabled
- **Azure subscription** with Owner or Contributor role
- **Access to Azure Landing Zone** with network connectivity configured


## 📁 Project Structure

```
/quickstart-azure-containers
├── .github/                   # GitHub Actions CI/CD workflows
│   └── workflows/
│       ├── pr-open.yml        # PR validation and deployment
│       ├── pr-close.yml       # PR cleanup
│       ├── pr-validate.yml    # Code quality checks
│       └── prune-env.yml      # Environment cleanup
├── infra/                     # Terraform infrastructure code
│   ├── main.tf                # Root configuration
│   ├── providers.tf           # Azure provider configuration
│   ├── variables.tf           # Global variables
│   ├── outputs.tf             # Infrastructure outputs
│   └── modules/               # Reusable infrastructure modules
│       ├── backend/           # App Service for NestJS API
│       ├── frontend/          # App Service for React SPA
│       ├── postgresql/        # PostgreSQL Flexible Server
│       ├── flyway/            # Database migration service
│       ├── network/           # VNet, subnets, NSGs
│       ├── monitoring/        # Log Analytics, App Insights
│       └── frontdoor/         # Azure Front Door CDN
├── backend/                   # NestJS TypeScript API
│   ├── src/                   # API source code
│   │   ├── users/             # User management module
│   │   ├── common/            # Shared utilities
│   │   └── middleware/        # Request/response middleware
│   ├── prisma/                # Database ORM configuration
│   │   └── schema.prisma      # Database schema definition
│   ├── test/                  # E2E API tests
│   └── Dockerfile             # Container build configuration
├── frontend/                  # React + Vite SPA
│   ├── src/                   # Frontend source code
│   │   ├── components/        # React components
│   │   ├── routes/            # Application routes
│   │   ├── services/          # API integration
│   │   └── interfaces/        # TypeScript interfaces
│   ├── e2e/                   # Playwright end-to-end tests
│   ├── public/                # Static assets
│   └── Dockerfile             # Container build configuration
├── migrations/                # Flyway database migrations
│   ├── sql/                   # SQL migration scripts
│   ├── Dockerfile             # Migration runner container
│   └── entrypoint.sh          # Migration execution script
├── terragrunt/                # Environment-specific configurations
│   ├── terragrunt.hcl         # Root configuration
│   ├── dev/                   # Development environment
│   ├── test/                  # Testing environment
│   ├── prod/                  # Production environment
│   └── tools/                 # Tools/utilities environment
├── docker-compose.yml         # Local development stack
├── initial-azure-setup.sh     # Azure setup automation script
└── package.json               # Monorepo configuration
```

## 🚀 Quick Start Guide

### 1. Clone and Setup Repository

```bash
# Use this template to create a new repository
gh repo create my-azure-app --template bcgov/quickstart-azure-containers --public

# Clone your new repository  
git clone https://github.com/your-org/my-azure-app.git
cd my-azure-app
```

### 2. Configure Azure Environment

The `initial-azure-setup.sh` script automates the complete Azure environment setup with OIDC authentication for GitHub Actions.

#### Prerequisites for Setup Script
- **Azure CLI** logged in (`az login`)
- **GitHub CLI** (optional, for automatic secret creation)
- **Azure subscription** with appropriate permissions
- **Existing Azure Landing Zone** resource group

#### Basic Setup Command

```bash
# Make the setup script executable
chmod +x initial-azure-setup.sh

# Run with required parameters
./initial-azure-setup.sh \
  --resource-group "ABCD-dev-networking" \
  --identity-name "my-app-github-identity" \
  --github-repo "myorg/my-azure-app" \
  --environment "dev" \
  --assign-roles "Contributor" \
  --create-storage \
  --create-github-secrets
```

#### Advanced Setup Examples

```bash
# Production setup with custom storage and multiple roles
./initial-azure-setup.sh \
  --resource-group "ABCD-prod-networking" \
  --identity-name "my-app-prod-identity" \
  --github-repo "myorg/my-azure-app" \
  --environment "prod" \
  --assign-roles "Contributor,Storage Account Contributor" \
  --contributor-scope "/subscriptions/your-subscription-id" \
  --create-storage \
  --storage-account "myappprodtfstate" \
  --create-github-secrets

# Dry run to preview changes
./initial-azure-setup.sh \
  --resource-group "ABCD-dev-networking" \
  --identity-name "my-app-github-identity" \
  --github-repo "myorg/my-azure-app" \
  --environment "dev" \
  --assign-roles "Contributor" \
  --create-storage \
  --dry-run
```

#### What the Setup Script Does

**🔐 Identity & Authentication:**
- Creates a user-assigned managed identity in your Landing Zone resource group
- Configures OIDC federated identity credentials for GitHub Actions
- Sets up environment-specific authentication (no secrets stored in Azure)

**💾 Terraform State Management:**
- Creates a secure Azure storage account for Terraform state files
- Enables blob versioning for state file protection
- Configures appropriate access permissions for the managed identity

**🔑 GitHub Integration:**
- Automatically creates GitHub environment if `--create-github-secrets` is used
- Sets up required secrets in your GitHub repository:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID` 
  - `AZURE_SUBSCRIPTION_ID`
  - `VNET_NAME` (derived from resource group)
  - `VNET_RESOURCE_GROUP_NAME`

**⚡ Azure Permissions:**
- Assigns specified roles to the managed identity
- Configures storage-specific permissions for Terraform state management
- Validates all configurations and provides verification

#### Script Parameters Reference

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--resource-group` | ✅ | Landing Zone resource group name | `ABCD-dev-networking` |
| `--identity-name` | ✅ | Name for the managed identity | `my-app-github-identity` |
| `--github-repo` | ✅ | Repository in format owner/repo | `myorg/my-azure-app` |
| `--environment` | ✅ | GitHub environment name | `dev`, `test`, `prod` |
| `--assign-roles` | ❌ | Comma-separated Azure roles | `Contributor,Storage Account Contributor` |
| `--contributor-scope` | ❌ | Scope for role assignment | `/subscriptions/xxx` (default: subscription) |
| `--create-storage` | ❌ | Create Terraform state storage | Flag (no value) |
| `--storage-account` | ❌ | Custom storage account name | `myapptfstate` (auto-generated if not specified) |
| `--create-github-secrets` | ❌ | Auto-create GitHub secrets | Flag (requires GitHub CLI) |
| `--dry-run` | ❌ | Preview changes without execution | Flag (no value) |

#### Post-Setup Verification

After running the script, verify the setup:

```bash
# Check managed identity was created
az identity show --name "my-app-github-identity" --resource-group "ABCD-dev-networking"

# Verify federated credentials
az identity federated-credential list --identity-name "my-app-github-identity" --resource-group "ABCD-dev-networking"

# Test GitHub Actions authentication (in your repository)
gh workflow run test-azure-connection  # if you have a test workflow
```

### 3. Configure GitHub Secrets (If Not Auto-Created)

If you didn't use the `--create-github-secrets` flag, manually add the following secrets to your GitHub repository (`Settings > Secrets and variables > Actions > Environment secrets`):

#### Required Environment Secrets
```bash
AZURE_CLIENT_ID=<managed-identity-client-id>
AZURE_TENANT_ID=<your-azure-tenant-id>
AZURE_SUBSCRIPTION_ID=<your-azure-subscription-id>
VNET_NAME=<landing-zone-vnet-name>
VNET_RESOURCE_GROUP_NAME=<landing-zone-rg-name>
```

#### Additional Repository Secrets (Application-Specific)
```bash
DB_MASTER_PASSWORD=<secure-database-password-min-12-chars>
```

💡 **Tip**: The setup script outputs the exact values to use for these secrets if you didn't use auto-creation.

### 4. Local Development Setup

```bash
# Install dependencies for all packages
npm install

# Start local development environment
docker-compose up -d

# Run database migrations
docker-compose exec migrations flyway migrate

# Start backend development server
cd backend && npm run start:dev

# Start frontend development server (in new terminal)
cd frontend && npm run dev
```

Access your local application:
- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:3000
- **Database**: localhost:5432 (postgres/default)

## 🚢 Deployment Process

### Automated Deployment via GitHub Actions

The repository includes comprehensive CI/CD workflows:

#### Pull Request Workflow (`pr-open.yml`)
```yaml
# Triggered on: Pull Request creation
# Actions:
# 1. Build and test frontend/backend containers
# 2. Run security scans and linting
# 3. Plan Terraform infrastructure changes
# 4. Deploy ephemeral environment for testing
# 5. Run end-to-end tests
```

#### Merge to Main Workflow
```yaml
# Triggered on: Merge to main branch
# Actions:
# 1. Build and push production containers
# 2. Deploy to staging environment
# 3. Run full test suite
# 4. Deploy to production (with approval)
```

### Manual Deployment

#### Deploy Infrastructure
```bash
# Navigate to environment configuration
cd terragrunt/dev  # or test/prod

# Initialize and plan
terragrunt init
terragrunt plan

# Apply changes
terragrunt apply
```

## 🗄️ Database Management

### Schema Migrations with Flyway

The template uses Flyway for database schema management:

#### Migration Files (`migrations/sql/`)
```sql
-- V1.0.0__init.sql
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Running Migrations
```bash
# Local development
docker-compose exec migrations flyway migrate

# Production (via container)
docker run --rm \
  -v $(pwd)/migrations/sql:/flyway/sql:ro \
  -e FLYWAY_URL=jdbc:postgresql://your-db:5432/app \
  -e FLYWAY_USER=your-user \
  -e FLYWAY_PASSWORD=your-password \
  flyway/flyway:11-alpine migrate
```

### Database Administration with CloudBeaver

Optional CloudBeaver container provides web-based database management:

- **Access**: `https://your-app-cloudbeaver.azurewebsites.net`
- **Authentication**: Azure AD integrated
- **Features**: Query editor, schema browser, data export/import

## 🔐 Security Features

### Azure Security Best Practices

#### Network Security
- **Private endpoints** for all Azure services
- **Network Security Groups** with least-privilege rules
- **Azure Front Door** with WAF protection
- **VNet integration** for App Services

#### Identity & Access Management
- **Managed identities** for service-to-service authentication
- **OIDC authentication** for GitHub Actions (no stored credentials)

#### Application Security
- **HTTPS everywhere** with TLS 1.3 minimum
- **Security headers** (HSTS, CSP, X-Frame-Options)
- **Container scanning** in CI/CD pipeline

### Security Configuration Examples

#### App Service Security (`infra/modules/backend/main.tf`)
```hcl
resource "azurerm_linux_web_app" "backend" {
  # ... other configuration
  
  site_config {
    minimum_tls_version = "1.3"
    ftps_state         = "Disabled"
    
    # IP restrictions for enhanced security
    ip_restriction {
      service_tag = "AzureFrontDoor.Backend"
      action      = "Allow"
      priority    = 100
      headers {
        x_azure_fdid = [var.frontend_frontdoor_resource_guid]
      }
    }
    
    ip_restriction {
      name       = "DenyAll"
      action     = "Deny"
      priority   = 500
      ip_address = "0.0.0.0/0"
    }
  }
}
```

## 📊 Monitoring & Observability

### Azure Monitor Integration

#### Application Insights Setup
```hcl
resource "azurerm_application_insights" "main" {
  name                = "${var.app_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
}
```

#### Log Analytics Workspace
```hcl
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.app_name}-log-analytics"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
}
```


### Monitoring Dashboards

Access monitoring through:
- **Azure Portal**: Resource group > Monitoring
- **Application Insights**: Performance, failures, dependencies
- **Log Analytics**: Custom queries and alerts
- **Azure Monitor**: Infrastructure metrics and alerts


### Testing in CI/CD

The GitHub Actions workflows include:
- **Unit tests** for frontend and backend
- **Integration tests** with test database
- **E2E tests** in containerized environment
- **Security scanning** of dependencies and containers
- **Performance testing** with load simulation

## 🏷️ Environment Management

### Multi-Environment Setup

The template supports multiple environments with Terragrunt:

```
terragrunt/
├── terragrunt.hcl          # Root configuration
├── dev/
│   └── terragrunt.hcl      # Development overrides
├── test/
│   └── terragrunt.hcl      # Testing overrides
├── prod/
│   └── terragrunt.hcl      # Production overrides
└── tools/
    └── terragrunt.hcl      # Tools/utilities environment
```

#### Environment-Specific Configuration

##### Development (`terragrunt/dev/terragrunt.hcl`)
```hcl
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  app_service_sku_name_backend  = "B1"
  app_service_sku_name_frontend = "B1"
  postgres_sku_name            = "B_Standard_B1ms"
  backend_autoscale_enabled    = false
  enable_psql_sidecar         = true
}
```

##### Production (`terragrunt/prod/terragrunt.hcl`)
```hcl
include "root" {
  path = find_in_parent_folders()
}

inputs = {
  app_service_sku_name_backend  = "P1V3"
  app_service_sku_name_frontend = "P1V3"
  postgres_sku_name            = "GP_Standard_D2s_v3"
  backend_autoscale_enabled    = true
  enable_psql_sidecar         = false
  postgres_ha_enabled         = true
}
```


## 🚨 Troubleshooting

### Common Issues and Solutions

#### 1. GitHub Actions Deployment Failures

**Issue**: OIDC authentication fails
```
Error: No subscription found. Run 'az account set' to select a subscription.
```

**Solution**: 
- Verify `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` secrets
- Ensure managed identity has proper federated credentials
- Check that repository URL matches federated identity configuration

#### 2. Terraform State Issues

**Issue**: State file conflicts or locks
```
Error: Error acquiring the state lock
```

**Solution**:
```bash
# Force unlock (use with caution)
terragrunt force-unlock <lock-id>

# Or check Azure storage account permissions
az storage blob list --account-name your-storage --container-name tfstate
```

#### 3. Container Deployment Issues

**Issue**: App Service fails to pull container
```
Error: Failed to pull image: unauthorized
```

**Solution**:
- Verify managed identity has `AcrPull` role on container registry
- Check container registry URL in app settings
- Ensure container image exists and is accessible

#### 4. Database Connection Issues

**Issue**: Backend cannot connect to PostgreSQL
```
Error: getaddrinfo ENOTFOUND your-postgres-server
```

**Solution**:
- Verify VNet integration and private endpoint configuration
- Check PostgreSQL firewall rules
- Ensure connection string environment variables are correct
- if you are using pgpool make sure you have this line `ssl: process.env.PGSSLMODE === 'require' ? { rejectUnauthorized: false } : false,`


### Debugging Tools

#### 1. Azure CLI Debugging
```bash
# Enable debug logging
az config set core.log_level=debug

# Check resource status
az webapp show --name your-app --resource-group your-rg

# View app service logs
az webapp log tail --name your-app --resource-group your-rg
```


## 📚 Additional Resources

### Documentation Links
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [NestJS Documentation](https://docs.nestjs.com/)
- [React + Vite Documentation](https://vitejs.dev/guide/)
- [Prisma Documentation](https://www.prisma.io/docs/)



## 🤝 Contributing

We welcome contributions to improve this template! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

**Built with ❤️ by the NRIDS Team**