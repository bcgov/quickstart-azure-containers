resource_group_name = "b9cee3-tools-quickstart-azure"
location            = "Canada Central"
existing_vnet_resource_group_name = "b9cee3-tools-networking"
postfix = "b9cee3-tools"
tf_storage_account_name = "runnertfb9cee3tools"
version_control_system_type         = "github"
version_control_system_organization = "bcgov"   # The organization name in the version control system
version_control_system_repository   = "quickstart-azure-containers" # The repository name in the version control system
# export TF_VAR_github_personal_access_token=<your_github_personal_access_token>

virtual_network_resource_group = "b9cee3-tools-networking"
virtual_network_name           = "b9cee3-tools-vwan-spoke"

container_app_subnet_name           = "ghr-aca"
container_app_subnet_address_prefix = "10.46.10.32/27" # must be a minimum size of `/27`

container_instance_subnet_name           = "ghr-aci"
container_instance_subnet_address_prefix = "10.46.10.16/28" # must be a minimum size of `/28`

private_endpoint_subnet_name           = "private-endpoints"
private_endpoint_subnet_address_prefix = "10.46.10.128/25"

compute_types = ["azure_container_app"]

tags = { # NOTE: Add this to avoid removing tags that have been inherited from the resource group (on subsequent runs)
  account_coding = "1337124E3035365027100000"
  billing_group  = "b9cee3"
  ministry_name  = "FLNR"
}
