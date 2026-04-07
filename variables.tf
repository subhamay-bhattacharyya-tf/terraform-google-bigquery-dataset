# -----------------------------------------------------------------------------
# BigQuery Dataset Module - Variables
# -----------------------------------------------------------------------------

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
    condition     = length(var.bigquery_dataset_config.dataset_id) == 0 || can(regex("^[a-zA-Z0-9_]{1,1024}$", var.bigquery_dataset_config.dataset_id))
    error_message = "dataset_id must be 1-1024 characters: letters, numbers, and underscores only."
  }

  validation {
    condition     = var.bigquery_dataset_config.project == null || can(regex("^[a-z][a-z0-9\\-]{4,28}[a-z0-9]$", var.bigquery_dataset_config.project))
    error_message = "project must be a valid GCP project ID (lowercase letters, digits, hyphens; 6-30 chars)."
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
    condition     = try(var.bigquery_dataset_config.default_table_expiration_ms >= 3600000, true)
    error_message = "default_table_expiration_ms must be at least 3600000 (1 hour) when set."
  }

  validation {
    condition     = try(var.bigquery_dataset_config.default_partition_expiration_ms >= 3600000, true)
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
