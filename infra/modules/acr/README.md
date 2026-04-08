# ACR (Azure Container Registry) module

This module wraps the Azure Verified Module (AVM) for Azure Container Registry:
- `Azure/avm-res-containerregistry-registry/azurerm`

## SKU / pricing notes

This repo intentionally avoids hard-coding SKU prices because they change over time.

General guidance:
- **Basic**: lowest cost, best for dev/test and light usage.
- **Standard**: higher throughput/limits than Basic for many production workloads.
- **Premium**: required if you need **Private Link / private endpoints** and other advanced features.

Official pricing details:
- https://azure.microsoft.com/en-us/pricing/details/container-registry/#pricing

## BC Gov Azure Landing Zone note

In BC Gov Azure Landing Zone, **public ACR is allowed** and **Basic SKU is allowed**.
If your design expects private connectivity (Private Link/private endpoints), use **Premium** and keep `public_network_access_enabled = false`.
