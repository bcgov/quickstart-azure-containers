plugin "azurerm" {
    enabled = true
    version = "0.28.0"
    source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}