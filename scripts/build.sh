#!/bin/bash

set -e

# Default to latest if not specified
CADDY_VERSION="${CADDY_VERSION:-latest}"

echo "Creating BOSH release for Caddy ${CADDY_VERSION}..."

# Export variables for package compilation
export CADDY_VERSION

# Create dev release
bosh create-release --force --timestamp-version

echo "Release created successfully!"
echo "Upload with: bosh upload-release"
echo "Deploy with: bosh -d caddy deploy manifests/caddy.yml --vars-file vars.yml"
 