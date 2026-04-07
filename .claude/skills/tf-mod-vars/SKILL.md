---
name: tf-mod-vars
description: >
  Use this skill whenever working with Terraform module variables.tf files
  across any cloud provider or data platform — including AWS, GCP, Azure,
  Snowflake, or custom modules. Trigger this skill when the user wants to:
  write, review, or debug a variables.tf file; define input variables for a
  Terraform module; use map-based config patterns (e.g. for_each-style
  resource maps); add validation blocks to variables; understand required vs
  optional fields and defaults; generate example tfvars or module call blocks;
  or work with complex nested object types in Terraform variables. Also trigger
  when the user pastes a variables.tf and asks how to use it, fill it in, or
  fix errors — regardless of whether they mention "skill" or "variables.tf"
  by name.
disable-model-invocation: true
---

# Terraform Module Variables — Universal Skill

This skill covers best practices for authoring, reading, and consuming
Terraform `variables.tf` files across **any provider** (AWS, GCP, Azure,
Snowflake, and beyond). It includes provider-specific reference sections
for common map-based module patterns.

---

## How to Use This Skill

1. **If a `variables.tf` was provided** → parse its variable blocks, extract
   the schema, then jump to the relevant [Provider Reference](provider-reference.md)
   section for type/validation guidance specific to that provider.
2. **If writing a new module** → follow [Variable Authoring Patterns](variable-authoring-patterns.md).
3. **If generating a module call or `.tfvars`** → follow [Consuming Variables](consuming-variables.md).
4. **If debugging a validation error** → check [Validation Patterns](validation-patterns.md).

---

## Variable Authoring Patterns

### Basic Variable Structure

```hcl
variable "resource_configs" {
  description = "What this variable controls and when to use it."
  type = map(object({
    required_field  = string
    optional_string = optional(string, "default_value")
    optional_number = optional(number, 0)
    optional_bool   = optional(bool, false)
    optional_list   = optional(list(string), [])
    optional_object = optional(object({
      sub_field = optional(string, null)
    }), null)
  }))
  default = {}
}
```

### Required vs Optional Fields

| Pattern | When to Use |
|---|---|
| `field = string` | Always required; no default possible |
| `field = optional(string, "val")` | Has a sensible default |
| `field = optional(string, null)` | Truly optional; omitted when null |
| `field = optional(list(string), [])` | Optional list, empty by default |
| `field = optional(object({...}), null)` | Optional nested block |

### Map-Based Config Pattern

Use `map(object({...}))` when the module manages **multiple instances** of the
same resource type. The **map key** is a Terraform-internal identifier (used
for state tracking and `for_each`), not the cloud resource name — always
include an explicit `name` field inside the object for the actual resource name.

```hcl
variable "resource_configs" {
  description = "Map of resource configurations keyed by logical name."
  type = map(object({
    name   = string               # actual cloud resource name
    region = string
    tags   = optional(map(string), {})
  }))
  default = {}
}
```

---

## Validation Patterns

Validations run at `terraform plan`/`apply` time, before provider API calls.
Always add them for constrained string enums, numeric ranges, and non-empty
required strings.

```hcl
# Non-empty string
validation {
  condition     = alltrue([for k, v in var.resource_configs : length(v.name) > 0])
  error_message = "Resource name must not be empty."
}

# Enum / allowed values
validation {
  condition = alltrue([
    for k, v in var.resource_configs :
    contains(["us-east-1", "us-west-2", "eu-west-1"], v.region)
  ])
  error_message = "region must be one of: us-east-1, us-west-2, eu-west-1."
}

# Numeric range
validation {
  condition = alltrue([
    for k, v in var.resource_configs :
    v.retention_days >= 1 && v.retention_days <= 365
  ])
  error_message = "retention_days must be between 1 and 365."
}

# CIDR format
validation {
  condition = alltrue([
    for k, v in var.resource_configs :
    can(cidrhost(v.cidr_block, 0))
  ])
  error_message = "cidr_block must be a valid CIDR notation."
}
```

---

## Consuming Variables

### Module Call Block

```hcl
module "my_resources" {
  source = "./modules/my-module"

  resource_configs = {
    primary = {
      name   = "prod-resource"
      region = "us-east-1"
      tags   = { env = "prod", team = "platform" }
    }
    secondary = {
      name   = "staging-resource"
      region = "us-west-2"
    }
  }
}
```

### terraform.tfvars / .auto.tfvars

```hcl
resource_configs = {
  primary = {
    name   = "prod-resource"
    region = "us-east-1"
  }
}
```

### Common Mistakes

- **Map key ≠ resource name.** The key (e.g. `primary`) is Terraform state
  identity. Use the `name` field inside the object for the actual cloud resource name.
- **Omitting required fields.** Fields without `optional(...)` are always
  required — Terraform errors at plan time if missing.
- **Wrong type for optional nested objects.** If an optional object has all
  optional sub-fields and you want defaults applied, pass `{}` not `null`.
- **Computed values as map keys.** `for_each` map keys must be known at plan
  time — avoid using resource attributes that aren't known until apply.

---

## Provider Reference

Jump to the relevant section for provider-specific type guidance, allowed
values, and complete examples.

- [AWS](aws.md)
- [GCP](gcp.md)
- [Azure](azure.md)
- [Snowflake](snowflake.md)

---

## AWS

### Common Field Types & Allowed Values

| Field | Type | Notes / Common Values |
|---|---|---|
| `region` | `string` | `us-east-1`, `us-west-2`, `eu-west-1`, `ap-southeast-1`, etc. |
| `environment` | `string` | `dev`, `staging`, `prod` |
| `instance_type` | `string` | `t3.micro`, `m5.large`, `c5.xlarge`, etc. |
| `tags` | `map(string)` | AWS limits 50 tags per resource |
| `retention_days` | `number` | CloudWatch Logs valid values: `1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653` |
| `deletion_protection` | `bool` | Recommended `true` for prod RDS/DynamoDB |
| `cidr_block` | `string` | Validate with `can(cidrhost(v, 0))` |
| `kms_key_id` | `string` | ARN format: `arn:aws:kms:region:account:key/id` |

### Example: S3 Bucket Module

```hcl
variable "bucket_configs" {
  description = "Map of S3 bucket configurations."
  type = map(object({
    name               = string
    region             = optional(string, "us-east-1")
    versioning_enabled = optional(bool, false)
    force_destroy      = optional(bool, false)
    lifecycle_days     = optional(number, 90)
    tags               = optional(map(string), {})
    cors_rules = optional(list(object({
      allowed_methods = list(string)
      allowed_origins = list(string)
      max_age_seconds = optional(number, 3000)
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.bucket_configs : length(v.name) >= 3 && length(v.name) <= 63])
    error_message = "S3 bucket name must be between 3 and 63 characters."
  }
}
```

```hcl
module "s3_buckets" {
  source = "./modules/s3"

  bucket_configs = {
    data_lake = {
      name               = "my-company-data-lake"
      versioning_enabled = true
      lifecycle_days     = 180
      tags               = { env = "prod", team = "data" }
    }
    artifacts = {
      name          = "my-company-artifacts"
      force_destroy = true
    }
  }
}
```

---

## GCP

### Common Field Types & Allowed Values

| Field | Type | Notes / Common Values |
|---|---|---|
| `project` | `string` | GCP project ID string (not project number); format: `^[a-z][a-z0-9\-]{4,28}[a-z0-9]$` |
| `location` | `string` | BigQuery multi-region: `US`, `EU`; regional: `US-CENTRAL1`, `US-EAST1`, `EUROPE-WEST1`, `ASIA-EAST1`, etc. |
| `labels` | `map(string)` | GCP equivalent of tags; keys/values must be lowercase |
| `dataset_id` | `string` | 1–1024 chars; letters, numbers, and underscores only |
| `default_table_expiration_ms` | `number` | Milliseconds; minimum 3600000 (1 hour) |
| `default_partition_expiration_ms` | `number` | Milliseconds; minimum 3600000 (1 hour) |

### Example: BigQuery Dataset Module

```hcl
variable "bigquery_dataset_config" {
  description = "Configuration for the BigQuery dataset."
  type = object({
    dataset_id                      = string
    project                         = optional(string, null)
    location                        = optional(string, "US")
    description                     = optional(string, null)
    friendly_name                   = optional(string, null)
    delete_contents_on_destroy      = optional(bool, false)
    default_table_expiration_ms     = optional(number, null)
    default_partition_expiration_ms = optional(number, null)
    labels                          = optional(map(string), {})
    access = optional(list(object({
      role           = optional(string, null)
      user_by_email  = optional(string, null)
      group_by_email = optional(string, null)
      domain         = optional(string, null)
      special_group  = optional(string, null)
      iam_member     = optional(string, null)
    })), [])
  })

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]{1,1024}$", var.bigquery_dataset_config.dataset_id))
    error_message = "dataset_id must be 1–1024 characters: letters, numbers, and underscores only."
  }

  validation {
    condition = var.bigquery_dataset_config.project == null || can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", var.bigquery_dataset_config.project))
    error_message = "project must be a valid GCP project ID (lowercase letters, digits, hyphens; 6–30 chars)."
  }

  validation {
    condition = contains(
      ["US", "EU", "US-CENTRAL1", "US-EAST1", "US-EAST4", "US-EAST5", "US-WEST1",
       "US-WEST2", "US-WEST3", "US-WEST4", "US-SOUTH1",
       "NORTHAMERICA-NORTHEAST1", "NORTHAMERICA-NORTHEAST2", "SOUTHAMERICA-EAST1", "SOUTHAMERICA-WEST1",
       "EUROPE-WEST1", "EUROPE-WEST2", "EUROPE-WEST3", "EUROPE-WEST4", "EUROPE-WEST6", "EUROPE-WEST8",
       "EUROPE-WEST9", "EUROPE-WEST10", "EUROPE-WEST12", "EUROPE-NORTH1", "EUROPE-CENTRAL2",
       "EUROPE-SOUTHWEST1", "ASIA-EAST1", "ASIA-EAST2", "ASIA-NORTHEAST1", "ASIA-NORTHEAST2",
       "ASIA-NORTHEAST3", "ASIA-SOUTHEAST1", "ASIA-SOUTHEAST2", "ASIA-SOUTH1", "ASIA-SOUTH2",
       "AUSTRALIA-SOUTHEAST1", "AUSTRALIA-SOUTHEAST2", "ME-CENTRAL1", "ME-WEST1", "AFRICA-SOUTH1"],
      upper(var.bigquery_dataset_config.location)
    )
    error_message = "location must be a valid BigQuery multi-region (US, EU) or regional location."
  }

  validation {
    condition = (
      var.bigquery_dataset_config.default_table_expiration_ms == null ||
      var.bigquery_dataset_config.default_table_expiration_ms >= 3600000
    )
    error_message = "default_table_expiration_ms must be at least 3600000 (1 hour) when set."
  }

  validation {
    condition = (
      var.bigquery_dataset_config.default_partition_expiration_ms == null ||
      var.bigquery_dataset_config.default_partition_expiration_ms >= 3600000
    )
    error_message = "default_partition_expiration_ms must be at least 3600000 (1 hour) when set."
  }

  validation {
    condition = alltrue([
      for a in var.bigquery_dataset_config.access :
      a.role == null || contains(["READER", "WRITER", "OWNER"], a.role)
    ])
    error_message = "access[*].role must be one of: READER, WRITER, OWNER."
  }

  validation {
    condition = alltrue([
      for a in var.bigquery_dataset_config.access :
      a.special_group == null || contains(
        ["projectOwners", "projectReaders", "projectWriters", "allAuthenticatedUsers"],
        a.special_group
      )
    ])
    error_message = "access[*].special_group must be one of: projectOwners, projectReaders, projectWriters, allAuthenticatedUsers."
  }
}
```

```hcl
module "bigquery_dataset" {
  source = "../../"

  bigquery_dataset_config = {
    dataset_id    = "my_analytics_dataset"
    project       = "my-gcp-project-123"
    location      = "US"
    description   = "Analytics dataset for the data platform team"
    friendly_name = "Analytics Dataset"
    labels        = { env = "prod", team = "data" }
    access = [
      { role = "READER", special_group = "projectReaders" },
      { role = "WRITER", user_by_email = "etl-sa@my-gcp-project-123.iam.gserviceaccount.com" }
    ]
  }
}
```

---

## Azure

### Common Field Types & Allowed Values

| Field | Type | Notes / Common Values |
|---|---|---|
| `resource_group_name` | `string` | Must already exist or be created separately |
| `location` | `string` | `eastus`, `westus2`, `westeurope`, `southeastasia`, etc. |
| `tags` | `map(string)` | Azure limits 50 tags per resource |
| `sku` | `string` | Varies by resource (see resource docs) |
| `tier` | `string` | `Free`, `Basic`, `Standard`, `Premium` (resource-dependent) |
| `replication_type` | `string` | Storage: `LRS`, `ZRS`, `GRS`, `RAGRS`, `GZRS`, `RAGZRS` |
| `min_tls_version` | `string` | `TLS1_0`, `TLS1_1`, `TLS1_2` — prefer `TLS1_2` |

### Example: Azure Storage Account Module

```hcl
variable "storage_account_configs" {
  description = "Map of Azure Storage Account configurations."
  type = map(object({
    name                      = string
    resource_group_name       = string
    location                  = optional(string, "eastus")
    account_tier              = optional(string, "Standard")
    account_replication_type  = optional(string, "LRS")
    enable_https_traffic_only = optional(bool, true)
    min_tls_version           = optional(string, "TLS1_2")
    blob_delete_retention_days = optional(number, 7)
    tags                      = optional(map(string), {})
    containers = optional(list(object({
      name        = string
      access_type = optional(string, "private")
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.storage_account_configs :
      contains(["Standard", "Premium"], v.account_tier)
    ])
    error_message = "account_tier must be Standard or Premium."
  }

  validation {
    condition = alltrue([
      for k, v in var.storage_account_configs :
      contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], v.account_replication_type)
    ])
    error_message = "account_replication_type must be one of: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS."
  }
}
```

```hcl
module "storage_accounts" {
  source = "./modules/azure-storage"

  storage_account_configs = {
    primary = {
      name                     = "mycompanyprodstore"
      resource_group_name      = "rg-prod-eastus"
      location                 = "eastus"
      account_tier             = "Standard"
      account_replication_type = "GRS"
      tags                     = { env = "prod", team = "platform" }
      containers = [
        { name = "raw-data",  access_type = "private" },
        { name = "processed", access_type = "private" }
      ]
    }
  }
}
```

---

## Snowflake

### `table_configs` Variable Schema

| Field | Type | Required | Default |
|---|---|---|---|
| `database` | `string` | ✅ | — |
| `schema` | `string` | ✅ | — |
| `name` | `string` | ✅ | — |
| `columns` | `list(object)` | ✅ | — |
| `table_type` | `string` | ❌ | `"PERMANENT"` |
| `drop_before_create` | `bool` | ❌ | `false` |
| `comment` | `string` | ❌ | `null` |
| `cluster_by` | `list(string)` | ❌ | `null` |
| `data_retention_time_in_days` | `number` | ❌ | `1` |
| `change_tracking` | `bool` | ❌ | `false` |
| `primary_key` | `object` | ❌ | `null` |
| `grants` | `list(object)` | ❌ | `[]` |

### Validation Rules

1. `name`, `database`, `schema` must not be empty.
2. `columns` must have at least one entry.
3. `data_retention_time_in_days` must be `0–90`.
4. `table_type` must be `"PERMANENT"`, `"TRANSIENT"`, or `"TEMPORARY"`.

### Column Object

```hcl
columns = [
  {
    name     = "ID"
    type     = "NUMBER(38,0)"
    nullable = false
    autoincrement = { start = 1, increment = 1, order = false }
  },
  {
    name    = "STATUS"
    type    = "VARCHAR(50)"
    default = "'ACTIVE'"    # string literals need inner single quotes
    comment = "Row status"
  }
]
```

> ⚠️ `autoincrement` and `default` are mutually exclusive on the same column.  
> ⚠️ `autoincrement` is only valid on `NUMBER`/`INT` types.

### Primary Key & Grants

```hcl
primary_key = {
  name = "pk_my_table"        # optional Snowflake constraint name
  keys = ["ID"]               # required: list of column names
}

grants = [
  { role_name = "ANALYST_ROLE", privileges = ["SELECT"] },
  { role_name = "ETL_ROLE",     privileges = ["SELECT", "INSERT", "UPDATE", "DELETE"] }
]
```

### Table Type Guidance

| Type | Fail-safe | Time Travel | Use Case |
|---|---|---|---|
| `PERMANENT` | ✅ | Up to 90 days | Production tables |
| `TRANSIENT` | ❌ | 0 or 1 day | Staging / intermediate tables |
| `TEMPORARY` | ❌ | 0 or 1 day | Session-scoped scratch tables |

### Snowflake Data Types Quick Reference

| Category | Examples |
|---|---|
| Numeric | `NUMBER(p,s)`, `INT`, `FLOAT`, `DOUBLE` |
| String | `VARCHAR(n)`, `STRING`, `TEXT` |
| Date/Time | `DATE`, `TIME`, `TIMESTAMP_NTZ`, `TIMESTAMP_LTZ`, `TIMESTAMP_TZ` |
| Boolean | `BOOLEAN` |
| Semi-structured | `VARIANT`, `OBJECT`, `ARRAY` |
| Binary | `BINARY`, `VARBINARY` |

### Example Module Call

```hcl
module "snowflake_tables" {
  source = "./modules/snowflake-table"

  table_configs = {
    customers = {
      database = "PROD_DB"
      schema   = "PUBLIC"
      name     = "CUSTOMERS"
      columns = [
        { name = "CUSTOMER_ID", type = "NUMBER(38,0)", nullable = false,
          autoincrement = { start = 1, increment = 1 } },
        { name = "EMAIL",       type = "VARCHAR(255)", nullable = false },
        { name = "CREATED_AT",  type = "TIMESTAMP_NTZ", nullable = false }
      ]
      primary_key = { keys = ["CUSTOMER_ID"] }
      grants = [
        { role_name = "ANALYST_ROLE", privileges = ["SELECT"] }
      ]
    }
  }
}
```
