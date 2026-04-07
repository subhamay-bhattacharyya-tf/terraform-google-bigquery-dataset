output "id" {
  description = "The fully qualified ID of the dataset."
  value       = module.bigquery_dataset.id
}

output "dataset_id" {
  description = "The dataset ID."
  value       = module.bigquery_dataset.dataset_id
}

output "project" {
  description = "The project containing the dataset."
  value       = module.bigquery_dataset.project
}

output "location" {
  description = "The geographic location of the dataset."
  value       = module.bigquery_dataset.location
}

output "self_link" {
  description = "The URI of the created resource."
  value       = module.bigquery_dataset.self_link
}

output "creation_time" {
  description = "Dataset creation time in milliseconds since the epoch."
  value       = module.bigquery_dataset.creation_time
}

output "last_modified_time" {
  description = "Dataset last modified time in milliseconds since the epoch."
  value       = module.bigquery_dataset.last_modified_time
}

output "etag" {
  description = "A hash of the resource."
  value       = module.bigquery_dataset.etag
}
