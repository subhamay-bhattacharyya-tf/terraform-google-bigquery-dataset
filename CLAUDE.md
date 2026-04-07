# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this module does

This is a **Terraform module** that creates and manages a single `google_bigquery_dataset` resource on GCP. The entire public interface is one input variable (`bigquery_dataset_config`) and the relevant outputs (id, dataset_id, project, location, self_link, creation_time, last_modified_time, etag). This will be used as a GitHub Repository Template. The actual modules will be implemented separately.

## Common commands

```bash
# Format check (must pass before commit)
terraform fmt -check -recursive

# Validate root module
terraform init -backend=false && terraform validate

# Validate the example
cd examples/bigquery_dataset/basic && terraform init -backend=false && terraform validate

# Run Terratest integration test (requires GCP auth + GOOGLE_CLOUD_PROJECT env var)
cd test && go test -v -timeout 30m -run TestBigQueryDatasetBasic ./bigquery_dataset_basic_test.go ./helpers_test.go

# Install local dev tools (Linux/devcontainer only)
bash install-tools.sh
bash install-tools.sh --tools=terraform,tflint,trivy  # install subset
bash install-tools.sh --dry-run                        # preview only

# Run pre-commit hooks
pre-commit run --all-files
```

## Architecture

```text
.                                # Root module — the publishable Terraform module
├── main.tf                      # Single google_bigquery_dataset resource
├── variables.tf                 # bigquery_dataset_config object variable with all validations
├── outputs.tf                   # Dataset attribute outputs
├── versions.tf                  # Terraform >= 1.3.0, google provider >= 7.23.0
├── examples/
│   └── bigquery_dataset/basic/  # Reference usage; CI validates this separately
└── test/
    ├── bigquery_dataset_basic_test.go   # Terratest: creates real dataset, asserts outputs, destroys
    └── helpers_test.go                  # Shared test helpers
```

## Key Conventions

- Terraform files use `/` directory with standard layout (main.tf, variables.tf, outputs.tf)
- GitHub Actions uses OIDC — no stored access keys
- All infrastructure changes go through Terraform — never modify GCP resources manually
- Site content changes deploy automatically via GitHub Actions on push to main
- This Terraform module only accepts one input of object type

The module uses a single structured `bigquery_dataset_config` object rather than flat variables. All validation (dataset ID naming rules, location enum, default table expiration bounds, access role enum, project ID format) lives in `variables.tf`.

## CI pipeline (`.github/workflows/ci.yaml`)

Runs on pushes/PRs to `main`, `feature/**`, `bug/**` when `.tf`, `examples/**`, or `test/**` files change:

1. **terraform-validate** — `fmt -check`, `init`, `validate` on the root module
2. **examples-validate** — `init` + `validate` on `examples/bigquery_dataset/basic` (needs step 1)
3. **terratest** — real GCP integration test via Workload Identity Federation (needs step 2); requires `GCP_PROJECT_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT` repo vars
4. **generate-changelog** — runs `git-cliff` on non-main branches (needs step 2)
5. **semantic-release** — runs only on `main` after steps 2 and 3; uses Conventional Commits to auto-version

## Commit message convention

Follows **Conventional Commits** — semantic-release uses this to determine the next version:

- `feat:` → minor bump
- `fix:` → patch bump
- `chore:`, `docs:`, `refactor:`, etc. → no release
- Breaking changes via `BREAKING CHANGE:` footer → major bump
