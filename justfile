# Caddy BOSH Release - Justfile
# Run `just --list` to see available commands

gcp_project := env_var("GCP_PROJECT")
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

# Create a dev release
create-dev:
    bosh create-release --force --timestamp-version

# Remove local dev release artifacts
clean:
    rm -rf dev_releases .dev_builds

# Upload blobs to blobstore (required before creating a final release)
upload-blobs:
    bosh upload-blobs

# Create a final release
create-final:
    bosh create-release --final
