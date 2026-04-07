# -----------------------------------------------------------------------------
# BigQuery Dataset Module - Main
# Creates and manages a Google BigQuery dataset.
# -----------------------------------------------------------------------------

resource "google_bigquery_dataset" "this" {
  dataset_id                      = var.bigquery_dataset_config.dataset_id
  project                         = var.bigquery_dataset_config.project
  location                        = var.bigquery_dataset_config.location
  description                     = var.bigquery_dataset_config.description
  friendly_name                   = var.bigquery_dataset_config.friendly_name
  delete_contents_on_destroy      = var.bigquery_dataset_config.delete_contents_on_destroy
  default_table_expiration_ms     = var.bigquery_dataset_config.default_table_expiration_ms
  default_partition_expiration_ms = var.bigquery_dataset_config.default_partition_expiration_ms
  labels                          = var.bigquery_dataset_config.labels

  dynamic "access" {
    for_each = var.bigquery_dataset_config.access
    content {
      role           = access.value.role
      user_by_email  = access.value.user_by_email
      group_by_email = access.value.group_by_email
      domain         = access.value.domain
      special_group  = access.value.special_group
      iam_member     = access.value.iam_member
    }
  }
}
