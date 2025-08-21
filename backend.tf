terraform {
  backend "gcs" {
    bucket = "github-actions-terraform-state-988"
    prefix = "terraform/state"
  }
}