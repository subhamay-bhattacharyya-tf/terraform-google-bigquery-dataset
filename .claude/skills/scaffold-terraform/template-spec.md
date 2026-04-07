# Terraform Template Specification

Generate these files in the `/` directory:

**main.tf:** _(delegate to `tf-mod-main` skill)_

- Single `google_bigquery_dataset` resource labeled `this`
- Follow the GCP provider reference and core authoring patterns from the `tf-mod-main` skill
- Wire all fields from `var.bigquery_dataset_config` directly to the resource
- Use a `dynamic "access"` block for the `access` list

**variables.tf:** _(delegate to `tf-mod-vars` skill)_

Use the `tf-mod-vars` skill to author this file. Apply the GCP provider reference and validation patterns. The module accepts a single input variable:

| Variable | Type | Required | Notes |
| --- | --- | --- | --- |
| `bigquery_dataset_config` | `object` | Yes | See attribute table below |

`bigquery_dataset_config` attributes:

| Attribute | Type | Required | Default | Validation |
| --- | --- | --- | --- | --- |
| `dataset_id` | `string` | Yes | — | 1–1024 chars; letters, numbers, underscores only |
| `project` | `string` | No | `null` | Must match GCP project ID format: `^[a-z][a-z0-9\-]{4,28}[a-z0-9]$` |
| `location` | `string` | No | `"US"` | Valid BigQuery multi-region or regional location |
| `description` | `string` | No | `null` | — |
| `friendly_name` | `string` | No | `null` | — |
| `delete_contents_on_destroy` | `bool` | No | `false` | — |
| `default_table_expiration_ms` | `number` | No | `null` | Must be ≥ 3600000 (1 hour) when set |
| `default_partition_expiration_ms` | `number` | No | `null` | Must be ≥ 3600000 (1 hour) when set |
| `labels` | `map(string)` | No | `{}` | Key-value pairs for governance |
| `access` | `list(object)` | No | `[]` | See access object schema below |

`access` object attributes:

| Attribute | Type | Required | Notes |
| --- | --- | --- | --- |
| `role` | `string` | No | One of: `READER`, `WRITER`, `OWNER` |
| `user_by_email` | `string` | No | Mutually exclusive with other member fields |
| `group_by_email` | `string` | No | Mutually exclusive with other member fields |
| `domain` | `string` | No | Mutually exclusive with other member fields |
| `special_group` | `string` | No | One of: `projectOwners`, `projectReaders`, `projectWriters`, `allAuthenticatedUsers` |
| `iam_member` | `string` | No | Mutually exclusive with other member fields |

**outputs.tf:**

- Outputs for all standard BigQuery dataset attributes:
  - `id` — The fully qualified ID of the dataset
  - `dataset_id` — The dataset ID
  - `project` — The project containing the dataset
  - `location` — The geographic location of the dataset
  - `self_link` — The URI of the created resource
  - `creation_time` — Dataset creation time in milliseconds since the epoch
  - `last_modified_time` — Dataset last modified time in milliseconds since the epoch
  - `etag` — A hash of the resource

**versions.tf:**

```hcl
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.23.0"
    }
  }
}
```

No `provider` block in `versions.tf` — provider configuration belongs in the root consuming module, not in a child module.

**examples/:** _(delegate to `tf-mod-examples` skill)_

Use the `tf-mod-examples` skill to scaffold the example matrix. The example directory structure follows:

```
examples/
└── bigquery_dataset/
    └── basic/        # Reference usage; CI validates this separately
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── README.md
```

Each example must be a self-contained, independently validatable Terraform configuration with its own `main.tf`, `variables.tf`, `terraform.tfvars`, and `README.md`.

**test/:**

- `test/bigquery_dataset_basic_test.go`: Terratest that creates a real BigQuery dataset using the `basic` example config, asserts all module outputs (id, dataset_id, project, location, self_link, creation_time, last_modified_time, etag), then destroys it.
- `test/helpers_test.go`: Shared test helpers (GCP project lookup from `GOOGLE_CLOUD_PROJECT` env var, common assertion utilities).

**CONTRIBUTING.md:**

Ensure Reporting Issues links to the current repository.

**README.md:** _(delegate to `tf-mod-readme` skill)_

Use the `tf-mod-readme` skill to generate this file. The skill will:

- Auto-resolve the repository name from the current git root
- Check and create the gist badge file if missing
- Populate all badge URLs pointing to the current repository
- Produce terraform-docs-compatible inputs/outputs tables
- Follow markdownlint rules (MD060 table column style)
