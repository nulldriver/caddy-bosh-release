# Caddy BOSH Release - Justfile
# Run `just --list` to see available commands

# Default recipe (shows help)
default:
    @just --list

# Create a dev release
create-dev:
    bosh create-release --force --timestamp-version

# Upload release to BOSH director
upload:
    bosh upload-release

# Deploy Caddy with vars file
deploy vars-file="vars.yml":
    bosh -d caddy deploy manifests/caddy.yml --vars-file {{vars-file}}

# Build and deploy in one step
build-deploy vars-file="vars.yml": create-dev upload (deploy vars-file)

# Follow Caddy logs
logs:
    bosh -d caddy logs caddy --follow

# SSH to Caddy instance
ssh:
    bosh -d caddy ssh caddy

# Validate Caddyfile on instance
validate:
    bosh -d caddy ssh caddy -c "/var/vcap/packages/caddy/bin/caddy validate --config /var/vcap/jobs/caddy/config/Caddyfile --adapter caddyfile"

# Show Caddy version on instance
version:
    bosh -d caddy ssh caddy -c "/var/vcap/packages/caddy/bin/caddy version"

# List Caddy modules on instance
list-modules:
    bosh -d caddy ssh caddy -c "/var/vcap/packages/caddy/bin/caddy list-modules"
