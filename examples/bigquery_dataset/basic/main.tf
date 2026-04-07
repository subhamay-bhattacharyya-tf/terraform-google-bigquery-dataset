module "bigquery_dataset" {
  source = "../../../"

  bigquery_dataset_config = {
    dataset_id = var.dataset_id
    project    = var.project
    location   = var.location
  }
}
