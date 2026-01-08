# ========================================================================================================
# Terraform Variables for Tools Environment -- Only static values should go here for tools specific tfvars
# NO SECRETS OR SENSITIVE VALUES SHOULD BE STORED IN THESE FILES
# ========================================================================================================

# -----------------------------------------------------------------------------
# App Service Configuration override for tools environment
# -----------------------------------------------------------------------------
app_service_sku_name_backend = "B1" # Basic tier for development (B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2)
enable_azure_proxy           = true
enable_apim = false
enable_frontdoor = false
enable_container_apps = false