# Copilot Instructions for Caddy BOSH Release

## Commit Message Format

All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type
Must be one of the following:
- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Code change that improves performance
- **test**: Adding or updating tests
- **chore**: Changes to build process, dependencies, tooling, or CI configuration

### Scope (Optional)
The scope should specify what part of the codebase is affected. Examples:
- `(caddy)` - Caddy package or job
- `(golang)` - Go toolchain package
- `(docs)` - Documentation updates
- `(spec)` - Test specifications

### Subject
- Use imperative mood ("add" not "added" or "adds")
- Do not capitalize the first letter
- Do not end with a period
- Limit to 50 characters

### Body (Optional)
- Separate from subject by a blank line
- Use imperative mood
- Wrap at 72 characters
- Explain what and why, not how
- Use bullet points for multiple changes

### Footer (Optional)
- Reference issues: `Fixes #123` or `Closes #456`
- Note breaking changes: `BREAKING CHANGE: description`

### Examples
```
feat(caddy): add support for DNS01 challenge

Implement DNS01 ACME challenge support using Google Cloud DNS provider.
This allows automated Let's Encrypt certificate management for domains
without public HTTP access.

- Add googleclouddns module to Caddy build
- Update job templates for DNS configuration
- Add environment variable support for GCP credentials

Fixes #42
```

```
docs: fix order of development commands

The clean step should run before create-dev to avoid stale artifacts.

Resolves issues with "Cannot find blob" errors during dev release creation.
```

```
fix(spec): correct BPM YAML template validation
```
