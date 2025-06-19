
az login

# read the namespace name and store it in a variable
$NAMESPACE = Read-Host "Enter the namespace name: " 

# Create a resource group for project resources
$RESOURCE_GROUP_PROJECT = "quickstart-azure"
az group create --name $RESOURCE_GROUP_PROJECT --location canadacentral --tags quickstart=true

# Create a storage account in canada central
az provider register --namespace Microsoft.Storage

$RESOURCE_GROUP_NAME = "$NAMESPACE-networking"
$VNET_NAME = "$NAMESPACE-vwan-spoke"


# Create a network security group
$NETWORK_SG = "gha-ci-cd-self-hosted-runner-nsg"
az network nsg create `
    --resource-group "$RESOURCE_GROUP_NAME" `
    --name $NETWORK_SG `
    --tags quickstart=true

# Create subnets for these 3 address spaces

# A subnet for the container app
# Requires a minimum size of /27 and be delegated to Microsoft.App/environments
az network vnet subnet create `
    --resource-group "$RESOURCE_GROUP_NAME" `
    --network-security-group "$NETWORK_SG" `
    --vnet-name $VNET_NAME `
    --delegations Microsoft.App/environments `
    --name container-app `
    --address-prefixes 10.46.10.32/27

# A subnet for the container instance
# Requires a minimum size of /28 and be delegated to Microsoft.ContainerInstance/containerGroups
az network vnet subnet create `
    --resource-group "$RESOURCE_GROUP_NAME" `
    --network-security-group "$NETWORK_SG" `
    --vnet-name $VNET_NAME `
    --delegations Microsoft.ContainerInstance/containerGroups `
    --name container-instance `
    --address-prefixes 10.46.10.16/28

# A subnet for the private endpoint
# There is no minimum size required. This subnet can be used for all Private Endpoints.
az network vnet subnet create `
    --resource-group "$RESOURCE_GROUP_NAME" `
    --network-security-group "$NETWORK_SG" `
    --vnet-name $VNET_NAME `
    --name private-endpoint `
    --service-endpoints Microsoft.Storage  `
    --address-prefixes 10.46.10.128/25

# fetch subnet id from different resource group first
$SUBNET_ID = az network vnet subnet show `
    --resource-group "$RESOURCE_GROUP_NAME" `
    --vnet-name "$VNET_NAME" `
    --name "private-endpoint" `
    --query id --out tsv

az storage account create `
    --name ghaciconfigstorage `
    --resource-group quickstart-azure `
    --location canadacentral `
    --sku Standard_LRS `
    --default-action Allow `
    --min-tls-version TLS1_2 `
    --https-only true `
    --allow-blob-public-access false `
    --subnet "$SUBNET_ID" `
    --public-network-access Disabled `
    --tags quickstart=true

# THIS WAS DONE LATER
#  az role assignment create --role "Storage Blob Data Contributor" --assignee 09d1805f-0d8c-4436-94ec-c2998c25399d --scope "/subscriptions/ffc5e617-7f2d-4ddb-8b57-33fc43989a8c/resourceGroups/quickstart-azure/providers/Microsoft.Storage/storageAccounts/ghaciconfigstorage"