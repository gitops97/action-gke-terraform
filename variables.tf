variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "vprofile-469703"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "vprofile-gke-cluster"
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

variable "desired_nodes" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}