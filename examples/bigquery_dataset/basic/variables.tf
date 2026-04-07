variable "dataset_id" {
  type        = string
  description = "The BigQuery dataset ID."
}

variable "project" {
  type        = string
  description = "The GCP project ID."
  default     = null
}

variable "location" {
  type        = string
  description = "The geographic location of the dataset."
  default     = "US"
}
