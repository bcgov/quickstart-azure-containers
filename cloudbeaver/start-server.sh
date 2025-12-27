#!/bin/sh
set -e

echo "Starting CloudBeaver configuration..."

# Create the workspace directory structure
mkdir -p "${WORKSPACE_PATH}/GlobalConfiguration/.dbeaver"

# Create the data sources configuration
cat > "${WORKSPACE_PATH}/GlobalConfiguration/.dbeaver/data-sources.json" <<EOF
{
  "folders": {},
  "connections": {
    "postgres-main": {
      "provider": "postgresql",
      "driver": "postgres-jdbc",
      "name": "PostgreSQL - ${POSTGRES_DATABASE}",
      "save-password": true,
      "show-system-objects": false,
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

echo "CloudBeaver configuration created. Starting server..."

# Start the CloudBeaver server using the official launch script
exec ./launch-product.sh