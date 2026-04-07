---
name: tf-mod-examples
description: >
  Generates Terraform module example configurations covering all meaningful
  combinations of input variables. Use this skill when the user asks to
  generate examples, scaffold example directories, create tfvars combinations,
  or produce a complete examples/ folder for a Terraform module. Trigger when
  the user says "generate all examples", "scaffold examples", "create example
  combinations", or "fill in the examples directory". Also trigger when the
  user shares a variables.tf and asks for example usage across all options.
---

# Terraform Module Examples — Generator Skill

This skill generates a complete `examples/` directory tree for a Terraform
module by reading `variables.tf` and producing one standalone example per
meaningful feature combination.

---

## How to Use This Skill

1. Read `variables.tf` (and `versions.tf` if present) from the current module root.
2. Identify every optional field and enumerate its allowed values from `validation` blocks or type annotations.
3. Derive the example matrix using the rules below.
4. Write each example as a self-contained directory under `examples/bigquery_dataset/` with its own `main.tf`, `variables.tf`, `terraform.tfvars`, and `README.md`.

---

## Step 1 — Enumerate Axes

For each optional field in the root `bigquery_dataset_config` object, record:

| Axis | Values |
|---|---|
| `location` | `US`, `EU`, `US-CENTRAL1`, `US-EAST1`, `EUROPE-WEST1`, `ASIA-EAST1` |
| `delete_contents_on_destroy` | `true`, `false` |
| `default_table_expiration_ms` | absent, `3600000` (1h), `86400000` (1d), `2592000000` (30d) |
| `default_partition_expiration_ms` | absent, `86400000` (1d) |
| `description` + `friendly_name` | absent, present |
| `labels` | absent, present |
| `access` | absent, single READER (special_group), single WRITER (user_by_email), multiple roles |

---

## Step 2 — Example Matrix

Do **not** generate the full cartesian product. Instead produce these named
examples, each exercising a distinct capability or realistic deployment pattern:

| Directory | Purpose | Key axes exercised |
|---|---|---|
| `basic/` | Minimal required fields only | defaults everywhere |
| `with-description/` | Human-readable metadata | `description`, `friendly_name` |
| `with-labels/` | Resource labelling for governance | `labels` map with env/team/cost-centre |
| `with-table-expiration/` | Auto-expire tables | `default_table_expiration_ms=86400000` |
| `with-partition-expiration/` | Auto-expire partitions | `default_partition_expiration_ms=86400000` |
| `with-access-reader/` | Grant read access to a group | `access` with `role=READER`, `special_group` |
| `with-access-writer/` | Grant write access to a service account | `access` with `role=WRITER`, `user_by_email` |
| `with-delete-contents/` | Allow destroy without manual table cleanup | `delete_contents_on_destroy=true` |
| `eu-location/` | EU data residency | `location=EU` |
| `us-central1-location/` | Regional placement (US-CENTRAL1) | `location=US-CENTRAL1` |
| `complete/` | All features combined | description, labels, table expiration, partition expiration, access (multi-role), EU location |

---

## Step 3 — File Structure per Example

Each example directory must contain exactly these four files:

```
examples/bigquery_dataset/<name>/
├── main.tf            # module call block only — no provider or terraform blocks
├── variables.tf       # re-declare only the variables consumed in main.tf
├── terraform.tfvars   # concrete values for every variable in variables.tf
└── README.md          # one-paragraph description + usage snippet
```

### `main.tf` template

```hcl
module "bigquery_dataset" {
  source = "../../../"

  bigquery_dataset_config = {
    dataset_id = var.dataset_id
    location   = var.location
    # ... only include fields relevant to this example
  }
}
```

### `variables.tf` template

```hcl
variable "dataset_id" {
  type        = string
  description = "The BigQuery dataset ID."
}

variable "location" {
  type        = string
  description = "The geographic location of the dataset."
  default     = "US"
}
```

### `terraform.tfvars` template

```hcl
dataset_id = "<example-slug>_dataset"
location   = "US"
```

### `README.md` template

```markdown
# <Example Title>

One sentence describing what this example demonstrates.

## Usage

\`\`\`bash
terraform init -backend=false
terraform validate
\`\`\`
```

---

## Step 4 — Validation Rules

After writing all files:

1. Run `terraform fmt -recursive examples/` to format all generated files.
2. Run `terraform init -backend=false && terraform validate` inside each example directory and report any errors.
3. Fix any errors before returning.

---

## Step 5 — Output Summary

After all files are written and validated, print a table:

| Example | Files written | Validated |
|---|---|---|
| `basic/` | 4 | ✓ |
| ... | ... | ... |
