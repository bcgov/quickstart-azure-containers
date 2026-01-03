# HTTP CLIENT 🔧

This folder contains HTTP client helpers and examples for interacting with Azure PaaS services (Key Vault, Search, etc.). It documents how to use the provided REST requests and how to route traffic through the local Chisel SOCKS tunnel using a Privoxy HTTP→SOCKS bridge so tools like VS Code REST Client and Postman can access Private Endpoints.

---

## Contents 📂

- `azure-kv/` — Key Vault REST request example and `.env` for local testing
  - `kv.http` — REST Client request to list secrets (uses `AZURE_KV_ENDPOINT` and `AZURE_ACCESS_TOKEN` from `.env`)
  - `.env` — local env file (do NOT commit secrets)
- `proxy/privoxy/` — tiny Alpine Privoxy image and README that bridges HTTP → SOCKS (used to make REST Client and Postman work with Chisel SOCKS)

---

## Quick flow overview 💡

1. Start a Chisel **SOCKS** tunnel to the Azure chisel _server_ (App Service running in your VNet).
2. Run the Privoxy container to expose an HTTP proxy on `127.0.0.1:8118` that forwards to your SOCKS tunnel (remote DNS + SNI via `socks5t`).
3. Point VS Code (User settings) / Postman to `http://127.0.0.1:8118` so Private Endpoint traffic goes through the tunnel.

---

## Start the Chisel client (example) 🧭

Recommended when running locally with Docker:

```powershell
# Bind SOСKS to 0.0.0.0 inside the container so Docker port publish works
docker run --rm -it -p 18080:1080 jpillora/chisel:latest client \
  --auth "tunnel:<PASSWORD>" \
  https://<your-chisel-server-url> \
  0.0.0.0:1080:socks
```

- Replace `<PASSWORD>` and `<your-chisel-server-url>` accordingly. The app service sets `CHISEL_AUTH="tunnel:<PASSWORD>"` in its Application Settings.
- Use `-p 18080:1080` to expose local SOCKS port at `127.0.0.1:18080` (client-side port selection is flexible).

---

## Build & run Privoxy bridge (example) 🧩

From repo root:

```powershell
# Build
docker build -t local/privoxy-socks-bridge:latest .\http-client\proxy\privoxy

# Run (Privoxy listens on 127.0.0.1:8118 and forwards to the local SOCKS)
docker run --rm -d --name privoxy \
  -p 127.0.0.1:8118:8118 \
  -e SOCKS_HOST=host.docker.internal \
  -e SOCKS_PORT=18080 \
  local/privoxy-socks-bridge:latest
```

Notes:
- If you run the chisel SOCKS client directly on the host (not in Docker), set `SOCKS_HOST=host.docker.internal` so the container can reach the host's SOCKS port.
- If everything works, `curl --proxy http://127.0.0.1:8118 https://ifconfig.me` should display the tunnel's outbound IP (not your local public IP).

---

## Configure clients

### VS Code (REST Client) ✅
- These are application-scoped settings (must be added to your **User (Default profile) settings**):

```jsonc
{
  "http.proxy": "http://127.0.0.1:8118",
  "http.proxySupport": "on",
  "rest-client.useHostProxy": true,
  "rest-client.proxy": "http://127.0.0.1:8118"
}
```

- After updating, run **Developer: Reload Window**.

### Postman ✅
- Settings → Proxy → Add a custom proxy configuration: Host `127.0.0.1`, Port `8118`, type HTTP/HTTPS. Do **not** enable proxy auth (Privoxy is not configured for auth).

---

## Key Vault test (create / read secret) 🔒

Acquire a token and PUT a secret (PowerShell example):

```powershell
$token = az account get-access-token --resource https://vault.azure.net --query accessToken -o tsv

# Create/update secret
curl.exe --proxy http://127.0.0.1:8118 `
  -X PUT `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json" `
  -d '{"value":"my-secret-value"}' `
  "https://<your-vault-name>.vault.azure.net/secrets/my-secret?api-version=7.4"

# Read secret
curl.exe --proxy http://127.0.0.1:8118 `
  -H "Authorization: Bearer $token" `
  "https://<your-vault-name>.vault.azure.net/secrets/my-secret?api-version=7.4"
```

- You can substitute `--proxy socks5h://127.0.0.1:18080` to test SOCKS directly.

---

## Using the provided REST Client request

- `azure-kv/kv.http` reads `AZURE_KV_ENDPOINT` and `AZURE_ACCESS_TOKEN` from `azure-kv/.env` (make sure your `.env` has the correct vault URL and a valid token).
- The REST Client will use the Privoxy bridge if VS Code settings are configured as above.

---

## Troubleshooting 🛠️

- 403 Forbidden with `x-ms-keyvault-network-info: addr=<your public ip>` → **request did not go through the proxy**. Check:
  - Privoxy is running and reachable: `curl --proxy http://127.0.0.1:8118 https://ifconfig.me`
  - REST Client / Postman configured to use `127.0.0.1:8118` (user-level settings for VS Code)
  - Chisel client bound to `0.0.0.0:1080:socks` so Docker port publish works
- DNS error or `Could not resolve host` → server-side private DNS not configured (Key Vault private endpoint DNS zone must be linked to the VNet where the App Service runs)
- `curl` works but VS Code does not → ensure application-scoped VS Code settings were set in User profile and window reloaded

---

## Security notes 🔐

- Never commit access tokens or passwords to the repository. Use ephemeral tokens (`az account get-access-token`) or managed identities for automation.
- Chisel auth (`tunnel:password`) is a secret — store in Azure Key Vault or Azure App Settings and rotate regularly.

---

## More resources

- `http-client/proxy/privoxy/README.md` — Privoxy bridge details
- Chisel: https://github.com/jpillora/chisel
- Azure Key Vault REST API documentation: https://learn.microsoft.com/azure/key-vault

---



