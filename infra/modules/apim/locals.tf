locals {
  apim_sku_tier = split("_", var.sku_name)[0]

  # Azure API Management does not support developer portal sign-in/sign-up configuration
  # for the Consumption SKU or any *V2 SKU tiers.
  apim_supports_portal_auth = !(local.apim_sku_tier == "Consumption" || endswith(local.apim_sku_tier, "V2"))
}
