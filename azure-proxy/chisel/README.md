# Azure Proxy

A secure tunnel proxy for local development access to Azure PostgreSQL databases using [Chisel](https://github.com/jpillora/chisel). This service creates a reverse proxy that allows developers to securely connect to Azure-hosted PostgreSQL databases from their local machines without exposing the database to public internet access.

## Overview

The Azure Proxy is built on Chisel, a fast TCP/UDP tunnel over HTTP. It provides:

- **Secure tunneling**: HTTPS-based communication with mandatory authentication
- **Local port forwarding**: Maps a local port to the remote Azure PostgreSQL database
- **Health checks**: Built-in health endpoint for monitoring and orchestration
- **Container-native**: Docker containerized for consistent deployment across environments
- **Automatic restart**: Includes retry logic for resilience

## Architecture

```
Local Machine (Port 5432)
        ↓
Chisel Client
        ↓
HTTPS Connection
        ↓
Azure Web App (Chisel Server)
        ↓
Azure PostgreSQL
```

## Local Development Setup

### Prerequisites

- Docker installed and running
- Access to the Azure Chisel server endpoint
- The Chisel authentication token

### Running Locally with Docker

Use the following command to establish a secure tunnel to the Azure PostgreSQL database:

```bash
docker run --rm -it -p 5462:5432 jpillora/chisel:latest client \
  --auth "tunnel:XXXXXXX" \
  https://${azure-db-proxy-app-service-url} \
  0.0.0.0:5432:${postgres_hostname}$:5432
```

#### Command Breakdown

- `--rm`: Automatically remove the container when it exits
- `-it`: Run in interactive mode with a TTY
- `-p 5462:5432`: Map local port `5462` to container port `5432` (PostgreSQL default)
- `jpillora/chisel:latest client`: Use Chisel in client mode to create an outbound tunnel
- `--auth "tunnel:XXXXXX"`: Authentication credentials for the Chisel server, replace with exact cred
- `https://${azure-db-proxy-app-service-url}`: The public URL of the Chisel server running in Azure, replace with actual URL
- `0.0.0.0:5432:${postgres_hostname}:5432`: Forward all interfaces on port 5432 to the remote PostgreSQL database on port 5432, replace actual host

#### Connecting to the Proxied DB

Once the Chisel tunnel is running, connect to PostgreSQL using after replacing with actual values:

```bash
psql -h localhost -p 5462 -U ${postgres_user} -d ${postgres_db}
```

Or in your application configuration, use:

```
Database Host: localhost
Port: 5462
Username: ${postgres_user}
Database: ${postgres_db}
```

## Azure Deployment

### Infrastructure as Code (Terraform)

The Azure Proxy is deployed as an Azure App Service using Terraform. Key resources:

- **App Service Plan**: Linux-based hosting for the proxy container
- **Web App**: Runs the Chisel server container
- **Application Insights**: Monitoring and diagnostics
- **Virtual Network Integration**: Securely connects to your VNet

### Terraform Variables

Key variables in the Terraform module:

| Variable | Description | Example |
|----------|-------------|---------|
| `app_name` | Base name for Azure resources | `quick-7fed-tools` |
| `app_env` | Deployment environment | `dev`, `test`, `prod` |
| `repo_name` | Repository name for resource naming | `quickstart-azure-containers` |
| `azure_db_proxy_image` | Docker image URL | `ghcr.io/bcgov/quickstart-azure-containers/azure-db-proxy:latest` |
| `app_service_sku_name_azure_db_proxy` | App Service SKU | `B1`, `B2`, `B3`, `S1` |
| `app_service_subnet_id` | VNet subnet for the App Service | Azure subnet ID |

### Required Environment Variables

When deployed to Azure App Service, the following environment variables are automatically configured:

| Variable | Purpose |
|----------|---------|
| `PORT` | The port Chisel server listens on (default: `80`) |
| `WEBSITES_PORT` | Azure App Service port mapping (default: `80`) |
| `CHISEL_AUTH` | Authentication token for Chisel server (e.g., `tunnel:password`) |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights monitoring |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | Application Insights instrumentation |

## Docker Image

### Building the Image

The Docker image is multi-stage and includes:

1. **Stage 1**: Extract Chisel binary from the official Chisel image
2. **Stage 2**: Minimal Alpine Linux base with only necessary dependencies

Build locally:

```bash
docker build -t azure-db-proxy:latest .
```

### Running the Image

The container is designed to run as a Chisel server. Basic startup:

```bash
docker run -d \
  -p 80:80 \
  -e CHISEL_AUTH="tunnel:your-auth-token" \
  -e PORT=80 \
  azure-db-proxy:latest
```

## Environment Variables

### Chisel Configuration

- **`CHISEL_AUTH`** (required): Authentication credentials in format `username:password`. Example: `tunnel:XXXXXX`
  - When set, clients must authenticate with these credentials
  - If not set, the server runs unauthenticated (not recommended for production)

- **`CHISEL_PORT`** (optional): Port the Chisel server listens on. Default: `80`
  - Must match the exposed port when running in containers

- **`CHISEL_HOST`** (optional): Host address to bind to. Default: `0.0.0.0` (all interfaces)

- **`CHISEL_ENABLE_SOCKS5`** (optional): Enable SOCKS5 proxy support. Default: `true`
  - Set to `false` if SOCKS5 is not needed

- **`CHISEL_EXTRA_ARGS`** (optional): Additional Chisel server arguments for advanced configuration

### Health Monitoring

- **`MAX_RETRIES`** (optional): Maximum retry attempts on failure. Default: `30`

- **`DELAY_SECONDS`** (optional): Delay between retries in seconds. Default: `5`

## Health Checks

### Health Endpoint

The proxy includes a built-in health check endpoint:

```
GET /healthz
```

**Response:**
```json
{
  "status": "healthy"
}
```



## Startup Process

The `start-chisel.sh` script orchestrates the startup:

1. **Validates Chisel binary**: Ensures Chisel is available
2. **Starts health backend**: Launches a minimal HTTP server on port 9999 for health checks
3. **Starts Chisel server**: Launches the tunnel server with configured authentication
4. **Health check reverse proxy**: Chisel reverse-proxies `/healthz` requests to the health backend
5. **Retry logic**: Automatically restarts on failure (up to `MAX_RETRIES` times)
6. **Graceful shutdown**: Responds to termination signals and cleans up processes

## Security Considerations

### Authentication

- Always set `CHISEL_AUTH` with a strong password in production
- Use format: `username:password` (e.g., `tunnel:YourSecurePasswordHere`)
- Store the password securely

### Network Security

- The proxy should only be accessible from trusted networks
- Restrict inbound access using ip restriction on app service
- Use HTTPS for all client connections to the proxy

### Access

- The proxy does not store or log database credentials
- PostgreSQL credentials are handled separately on the client side
- Always use encrypted connections (SSL/TLS) when available

## Monitoring and Logs

### Application Insights

The proxy sends logs and metrics to Application Insights when configured:

- HTTP request logs
- Container logs
- Platform diagnostics
- Performance metrics

View logs in Azure Portal:
1. Navigate to the App Service resource
2. Go to **Application Insights** → **Application Map** or **Logs**

### Container Logs

View real-time logs in Azure Portal:

```
App Service → Log stream
```

Or via Azure CLI:

```bash
az webapp log tail --resource-group <rg-name> --name <web-app-name>
```

## Troubleshooting

### Connection Refused

**Problem**: `Connection refused` when connecting to `localhost:5462`

**Solution**: 
- Verify the Chisel tunnel is running: `docker ps`
- Check the port mapping: `-p 5462:5432` must be in the docker command
- Ensure the Azure proxy endpoint is reachable

### Authentication Failed

**Problem**: `Authorization failed` or `Auth failed` in logs

**Solution**:
- Verify the `--auth` parameter matches the server's `CHISEL_AUTH` setting
- Ensure the password is correct and not expired
- Check Azure Key Vault for the current credentials

### Cannot Resolve Hostname

**Problem**: `Cannot resolve hostname 'xxxxx.database.azure.com'`

**Solution**:
- Verify the Azure proxy server has network access to the PostgreSQL database
- Check Network Security Group (NSG) rules allow outbound traffic on port 5432
- Ensure the PostgreSQL server name is correct

### High Latency

**Problem**: Slow database connections through the proxy

**Solution**:
- The Chisel server adds minimal overhead; check the Azure App Service plan tier
- Upgrade to a higher SKU (B2, B3, S1) if running on B1
- Check network latency between regions

## Related Resources

- [Chisel Documentation](https://github.com/jpillora/chisel)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure PostgreSQL Documentation](https://docs.microsoft.com/azure/postgresql/)
- [Azure Key Vault for Secrets Management](https://docs.microsoft.com/azure/key-vault/)

## Contributing

When modifying the proxy:

1. Update `Dockerfile` for image changes
2. Update `start-chisel.sh` for startup logic changes
3. Test locally with the Docker command above
4. Update this README with any new features or configuration options
5. Push the updated image to the container registry
