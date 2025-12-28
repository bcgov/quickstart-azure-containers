#!/bin/sh
set -e

echo "Starting CloudBeaver configuration..."

# The CloudBeaver server log shows the workspace is initialized at:
#   /opt/cloudbeaver/workspace
# In this repo/App Service config, WORKSPACE_PATH is set to that same path.
: "${WORKSPACE_PATH:=/opt/cloudbeaver/workspace}"

CONFIG_DIR="${WORKSPACE_PATH}/GlobalConfiguration/.dbeaver"
CONFIG_FILE="${CONFIG_DIR}/data-sources.json"

# Create the workspace directory structure
mkdir -p "${CONFIG_DIR}"

# Create the data sources configuration
cat > "${CONFIG_FILE}" <<EOF
{
  "folders": {},
  "connections": {
    "postgres-main": {
      "provider": "postgresql",
      "driver": "postgres-jdbc",
      "name": "PostgreSQL - ${POSTGRES_DATABASE}",
      "save-password": true,
      "show-system-objects": true,
      "read-only": false,
      "configuration": {
        "host": "${POSTGRES_HOST}",
        "port": "${POSTGRES_PORT}",
        "database": "${POSTGRES_DATABASE}",
        "url": "jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE}",
        "configurationType": "MANUAL",
        "type": "dev",
        "provider-properties": {
          "@dbeaver-show-non-default-db@": "false"
        },
        "auth-model": "native"
      },
      "credentials": {
        "userName": "${POSTGRES_USER}",
        "userPassword": "${POSTGRES_PASSWORD}"
      }
    }
  },
  "connection-types": {
    "dev": {
      "name": "Development",
      "color": "255,255,255",
      "description": "Regular development database",
      "auto-commit": true,
      "confirm-execute": false,
      "confirm-data-change": false,
      "auto-close-transactions": false
    }
  }
}
EOF

echo "CloudBeaver configuration created at ${CONFIG_FILE}. Starting server..."

# Start the CloudBeaver server using the official launch script
cd /opt/cloudbeaver
exec ./launch-product.sh