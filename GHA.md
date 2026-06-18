# GitHub Actions Workflows Guide

This repository uses GitHub Actions to:
- Build and publish container images to GitHub Container Registry (GHCR)
- Run Terraform plan/apply/destroy using Azure OIDC authentication
- Deploy an Azure Bastion + Linux jumpbox into the BC Gov ALZ spoke VNet

The workflows are defined in `.github/workflows/`.

## How deployments work (high level)

1. **Build containers**
	 - Reusable workflow: `.github/workflows/.builds.yml`
	 - Builds and pushes images for: `backend`, `frontend`, `migrations`

2. **Terraform plan/apply/destroy**
	 - Reusable workflow: `.github/workflows/.deployer.yml`
	 - Uses `azure/login@v2` (OIDC) and runs `infra/deploy-terraform.sh`.
	 - Terraform is executed from `infra/` with `-var-file=<environment>.tfvars`.

3. **Remote state**
	 - CI configures the AzureRM backend dynamically using environment variables consumed by `infra/deploy-terraform.sh`.
	 - State key format used by CI:
		 - `<stack_prefix>/<app_env>/terraform.tfstate`

## Required GitHub configuration

### Environment secrets (per environment)

These are read by `.github/workflows/.deployer.yml`:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

Networking inputs (used by Terraform variables):
- `VNET_RESOURCE_GROUP_NAME`
- `VNET_NAME`
- `VNET_ADDRESS_SPACE`
- `BASTION_SUBNET_ADDRESS_PREFIX` — must be `/26` or larger (used by `deploy-vm-bastion.yml`)
- `JUMPBOX_SUBNET_ADDRESS_PREFIX` — e.g. `/28` (used by `deploy-vm-bastion.yml`)
- `VM_ADMIN_LOGIN_PRINCIPAL_IDS` — comma-separated Entra object IDs (GUIDs) of users who can log in to the jumpbox

### Environment variables (per environment)

- `STORAGE_ACCOUNT_NAME`
	- Used as the Terraform backend storage account name (`BACKEND_STORAGE_ACCOUNT`).

### Optional secrets (tests)

The reusable test workflow `.github/workflows/.tests.yml` expects:
- `SONAR_TOKEN_BACKEND`
- `SONAR_TOKEN_FRONTEND`

## Workflows you’ll run

### PR workflow (build + terraform plan)

Workflow file: `.github/workflows/pr-open.yml`

Triggers:
- `pull_request`
- `workflow_dispatch`

Jobs:
- **Builds**: calls `.github/workflows/.builds.yml`
	- Tags include PR number (or `manual`), `manual-<run_number>`, and `latest`.
- **Plan Stack**: calls `.github/workflows/.deploy_stack.yml` with:
	- `environment_name: tools`
	- `command: plan`
	- `tag: <PR number or latest>`
	- `app_env: <PR number or latest>`
- **Lint**: runs `tflint --recursive` in `infra/`.

Notes:
- The plan job uses the `tools.tfvars` file because `environment_name` is set to `tools`.
- `app_env` is separate from `environment_name` and influences resource naming and the state key.

### Deploy VM + Bastion

Workflow file: `.github/workflows/deploy-vm-bastion.yml`

Triggers:
- `workflow_dispatch` — inputs: `environment` (dev / test / prod / tools) and `terraform_command` (apply / plan / destroy)

What it does:
- Deploys an Azure Bastion host and a Linux jumpbox VM into the selected environment's spoke VNet using the [`bcgov/action-deployer-vm-bastion-alz`](https://github.com/bcgov/action-deployer-vm-bastion-alz) composite action.
- VM options (size, SKU, feature toggles) are passed as inline `with:` inputs directly in the workflow file.
- Reads subnet CIDRs and OIDC credentials from GitHub Environment secrets (see above).
- Terraform state is stored in the same backend storage account as the main stack.

Notes:
- The OIDC identity needs **Contributor** on the subscription/resource group and **User Access Administrator** (for RBAC assignments to the jumpbox).
- `BASTION_SUBNET_ADDRESS_PREFIX` must be `/26` or larger — Terraform validation rejects anything smaller.
- `VM_ADMIN_LOGIN_PRINCIPAL_IDS` must contain Entra **object IDs** (GUIDs), not UPNs.
- The action reference (`@feat/reusable-action`) should be pinned to an immutable SHA before going to production.

### Manual destroy

Workflow file: `.github/workflows/prune-env.yml`
- Triggered via `workflow_dispatch`.
- Calls `.github/workflows/.destroy_stack.yml` which ultimately calls `.github/workflows/.deployer.yml` with `command: destroy`.

## Terraform execution details (CI)

Terraform is run via `infra/deploy-terraform.sh`.

CI sets:
- `CI=true` (auto-approve for apply/destroy)
- `ARM_USE_OIDC=true`
- `TF_VAR_use_oidc=true`
- `TF_VAR_subscription_id`, `TF_VAR_tenant_id`, `TF_VAR_client_id`

CI also sets container image variables (all using GHCR):
- `TF_VAR_api_image=ghcr.io/<owner>/<repo>/backend:<tag>`
- `TF_VAR_frontend_image=ghcr.io/<owner>/<repo>/frontend:<tag>`
- `TF_VAR_flyway_image=ghcr.io/<owner>/<repo>/migrations:<tag>`

## Auto-import behavior for "already exists" errors

When `terraform apply` fails with an Azure error like “a resource with the ID ... already exists”, `infra/deploy-terraform.sh`:
- Parses the error output using `infra/scripts/extract-import-target.sh`
- Runs `terraform import` with the same var context
- Retries apply (up to 3 attempts)

