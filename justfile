# Caddy BOSH Release - Justfile
# Run `just --list` to see available commands

gcp_project := env_var_or_default("GCP_PROJECT", "")
blobstore_bucket := "caddy-bosh-release-blobs"

# Default recipe (shows help)
default:
    @just --list

# Install test dependencies and run job template unit tests
test:
    bundle config set --local path vendor/bundle
    bundle install
    bundle exec rspec

# Run unit tests without reinstalling gems (faster)
test-quick:
    bundle exec rspec

# Create the GCS blobstore bucket (one-time setup)
create-bucket project=gcp_project:
    gsutil mb -p {{project}} gs://{{blobstore_bucket}}

# Remove local dev release artifacts
clean:
    rm -rf dev_releases .dev_builds

# Create a dev release
create-dev:
    bosh create-release --force --timestamp-version

# Upload blobs to blobstore (required before creating a final release)
upload-blobs:
    bosh upload-blobs

# Create a final release with the given semantic version (e.g. just create-final 1.0.0)
create-final version:
    bosh create-release --final --version {{version}} --force

# Publish the latest final release as a GitHub release with the tarball as an asset
publish:
    #!/usr/bin/env bash
    set -euo pipefail
    version=$(ls releases/caddy/caddy-*.yml 2>/dev/null | sed 's/.*caddy-\(.*\)\.yml/\1/' | sort -V | tail -1)
    if [[ -z "$version" ]]; then
        echo "No final release found. Run 'just create-final' first."
        exit 1
    fi
    tarball="releases/caddy/caddy-${version}.tgz"
    if [[ ! -f "$tarball" ]]; then
        echo "Tarball $tarball not found. Regenerating..."
        bosh create-release "releases/caddy/caddy-${version}.yml" --tarball "$tarball"
    fi
    gh release create "v${version}" "$tarball" --title "v${version}" --generate-notes
