terraform {
  source = "../../..//infrastructure//api"
}



locals {
  region                  = "ca-central-1"

  # Terraform remote S3 config
  stack_prefix          = get_env("stack_prefix")
  tf_remote_state_prefix  = "terraform-remote-state" # Do not change this, given by cloud.pathfinder.
  target_env              = get_env("target_env")
  aws_license_plate          = get_env("aws_license_plate")
  app_env          = get_env("app_env")
  statefile_bucket_name   = "${local.tf_remote_state_prefix}-${local.aws_license_plate}-${local.target_env}" 
  statefile_key           = "${local.stack_prefix}/${local.app_env}/api/terraform.tfstate"
  statelock_table_name    = "${local.tf_remote_state_prefix}-lock-${local.aws_license_plate}"
  flyway_image              = get_env("flyway_image")
  api_image          = get_env("api_image")
  rds_app_env = (contains(["dev", "test", "prod"], "${local.app_env}") ? "${local.app_env}" : "dev") # if app_env is not dev, test, or prod, default to dev 
  
}

# Remote S3 state for Terraform.
generate "remote_state" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.statefile_bucket_name}"
    key            = "${local.statefile_key}"            # Path and name of the state file within the bucket
    region         = "${local.region}"                    # AWS region where the bucket is located
    dynamodb_table = "${local.statelock_table_name}"
    encrypt        = true
  }
}
EOF
}


generate "tfvars" {
  path              = "terragrunt.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
  app_name="${local.stack_prefix}-node-api-${local.app_env}"
  db_cluster_name = "${local.stack_prefix}-aurora-${local.rds_app_env}"
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region  = "${local.region}"
}
EOF
}