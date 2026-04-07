---
name: scaffold-terraform
description: Generate complete Terraform Google Module for provisioning a BigQuery Dataset with the given specifications
disable-model-invocation: true
argument-hint: "[region] [project]"
---

Generate a complete Terraform Google Module for provisioning a BigQuery Dataset with the given specifications:

Use $ARGUMENTS for optional overrides:
- $0 = GCP region (default: us-central1)
- $1 = GCP Project name (default: portfolio-site)

## What to Generate

Read `template-spec.md` in this skill folder for the full Terraform module specification.

Generate all files in the `/` directory following the template spec, delegating to the individual skills below for each configuration file:

## Delegation Map

| File / Section | Skill to invoke |
|---|---|
| `variables.tf` | **`tf-mod-vars`** — follow its variable authoring patterns, validation rules, and GCP provider reference for the `bigquery_dataset_config` object |
| `main.tf` | **`tf-mod-main`** — follow its core authoring patterns and GCP provider reference for the `google_bigquery_dataset` resource |
| `examples/` | **`tf-mod-examples`** — follow its example matrix and file-structure rules to scaffold all example directories |
| `README.md` | **`tf-mod-readme`** — follow its template exactly, auto-resolve the repository name, and ensure the gist badge file exists |

Generate all other files (`outputs.tf`, `versions.tf`, `test/`, `CONTRIBUTING.md`, `.github/workflows/ci.yaml`) directly from `template-spec.md`.

## After Generation

- [ ] List all files created
- [ ] Show a summary of resources that will be provisioned
- [ ] Remind the engineer to review the files and run `/tf-plan` when ready
