# Caddy BOSH Release

A BOSH release for [Caddy Server](https://caddyserver.com/) v2 with Google Cloud DNS support for automated Let's Encrypt certificate management.

## Features

- **Pre-configured DNS Module**: Built with Google Cloud DNS provider module
- **Automatic HTTPS**: Let's Encrypt integration with DNS challenge support
- **BPM Process Management**: Uses BOSH Process Manager for isolation and resource limits
- **Persistent Certificate Storage**: Certificates stored on persistent disk
- **Flexible Configuration**: Raw Caddyfile passthrough with ERB templating for variables and secrets

## Included DNS Provider Modules

This release includes the following DNS provider module:

- Google Cloud DNS (`googleclouddns`)

## Requirements

- BOSH CLI
- BPM release (colocated with Caddy job)
- Internet connectivity on compilation VMs (for downloading Go and Caddy modules during package compilation)
- Persistent disk for certificate storage

**Note**: Offline/air-gapped deployments are not currently supported.

## Quick Start

### 1. Create Dev Release

```bash
bosh create-release --force --timestamp-version
```

Or use the justfile:

```bash
just create-dev
```

### 2. Upload Release

```bash
bosh upload-release
```

### 3. Deploy

Create a `vars.yml` file (see `manifests/vars-example.yml`):

```yaml
email: admin@example.com
network_name: default
gcp_project: my-gcp-project
google_application_credentials: '{"type": "service_account", ...}'
```

**For testing**, use the Let's Encrypt staging endpoint to avoid rate limits in your Caddyfile:

```
{
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

```

Deploy:

```bash
bosh -d caddy deploy manifests/caddy.yml --vars-file vars.yml
```

Or use justfile:

```bash
just deploy vars-file=vars.yml
```

## Configuration

### Job Properties

| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| `caddyfile` | Yes | - | Raw Caddyfile configuration content (supports ERB for variable interpolation) |
| `env` | No | `{}` | Additional environment variables to configure DNS providers and other settings |

### Example Caddyfile with DNS Challenge

```caddyfile
{
  # Use staging CA for testing to avoid rate limits. Comment out for production.
  acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  email admin@example.com
}

example.com {
  tls {
    dns googleclouddns {
      gcp_project {env.GCP_PROJECT}
    }
  }
  
  reverse_proxy backend1:8080 backend2:8080
}
```

### Environment Variables

The `env` property allows you to pass environment variables to Caddy. For Google Cloud DNS, you can provide credentials in two ways:

1. **Service Account JSON**: Set `GOOGLE_APPLICATION_CREDENTIALS` with the JSON content. The BOSH job will write it to a file and set the environment variable to the file path.
2. **GCP Project**: Set `GCP_PROJECT` to specify the Google Cloud project ID.

Example in deployment manifest:

```yaml
properties:
  env:
    GCP_PROJECT: my-project
    GOOGLE_APPLICATION_CREDENTIALS: |
      {
        "type": "service_account",
        "project_id": "my-project",
        ...
      }
  caddyfile: |
    {
      email admin@example.com
    }
    
    example.com {
      tls {
        dns googleclouddns {
          gcp_project {env.GCP_PROJECT}
        }
      }
      reverse_proxy localhost:8080
    }
```

## Package Compilation

This release compiles Caddy during package build time (when you run `bosh create-release`). The compilation:

- Downloads Go
- Installs xcaddy
- Builds Caddy with all DNS provider modules

BOSH caches compiled packages, so recompilation only happens when package contents change.

## Deployment Example

See `manifests/caddy.yml` for a complete example. Key points:

1. **BPM Colocated**: The `bpm` job must be colocated with the `caddy` job
2. **Persistent Disk**: Required for certificate storage (10GB recommended)
3. **Variable Interpolation**: Use `((variable_name))` in Caddyfile and pass via `--vars-file`

## Troubleshooting

### Compilation Failures

**Go Download Fails**:
- Check internet connectivity on compilation VMs
- Verify firewall rules allow HTTPS to go.dev

**Module Build Fails**:
- Check compilation logs: `bosh task <task-id> --debug`
- Verify internet connectivity to proxy.golang.org

### Runtime Issues

**Certificate Acquisition Fails**:
- Check DNS provider credentials
- Verify DNS provider API access and permissions (for GCP: ensure service account has DNS Admin role)
- Check Caddy logs: `bosh -d caddy logs caddy`

**Validation Fails on Deploy**:
- Check Caddyfile syntax
- Ensure ERB variables are properly interpolated

**Port Binding Fails**:
- Verify security groups allow ports 80 and 443
- Check for port conflicts with other jobs

## Development

### Using justfile

```bash
# Create dev release
just create-dev

# Upload release
just upload

# Deploy with vars file
just deploy vars-file=vars.yml

# View logs
just logs

# Validate configuration on instance
just validate

# Check Caddy version
just version

# List all modules
just list-modules

# Clean up
just clean

# Build and deploy in one command
just build-deploy vars-file=vars.yml
```

### Manual Commands

```bash
# Create dev release
bosh create-release --force --timestamp-version

# Upload and deploy
bosh upload-release
bosh -d caddy deploy manifests/caddy.yml --vars-file vars.yml

# Check logs
bosh -d caddy logs caddy --follow

# SSH to instance
bosh -d caddy ssh caddy

# Validate Caddyfile
bosh -d caddy ssh caddy -c "/var/vcap/packages/caddy/bin/caddy validate --config /var/vcap/jobs/caddy/config/Caddyfile --adapter caddyfile"
```

## Architecture

### Packages

- **golang**: Downloads and installs Go toolchain for compilation
- **caddy**: Compiles Caddy with Google Cloud DNS provider module using xcaddy

### Jobs

- **caddy**: Runs Caddy server with BPM process management

### BPM Configuration

- **Capabilities**: NET_BIND_SERVICE (bind to ports 80/443)
- **Persistent Disk**: Mounted at `/var/vcap/store/caddy` for certificates
- **Ephemeral Disk**: Mounted at `/var/vcap/data/caddy` for temporary data

## Updating Caddy Version

To update to a newer version of Caddy:

1. Edit [packages/caddy/packaging](packages/caddy/packaging)
2. Change `CADDY_VERSION="v2.10.2"` to desired version
3. Create new release: `bosh create-release --force`

## Adding Additional DNS Modules

To add more Caddy DNS provider modules beyond Google Cloud DNS:

1. Edit [packages/caddy/packaging](packages/caddy/packaging)
2. Add module to `CADDY_MODULES` array:
   ```bash
   CADDY_MODULES=(
     "github.com/caddy-dns/googleclouddns"
     "github.com/caddy-dns/cloudflare"
     "github.com/caddy-dns/route53"
   )
   ```
3. Create new release: `bosh create-release --force`

Available DNS provider modules can be found at: https://github.com/caddy-dns

## License

[Add your license here]

## Contributing

Contributions welcome! Please open an issue or pull request.
