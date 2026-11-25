terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0, < 8.0"
    }
  }

  # State is LOCAL by default so the repo runs with no extra infrastructure.
  # For remote state + locking, copy backend.tf.example to backend.tf and
  # follow "Remote state (GCS backend)" in the README.
}

provider "google" {
  project = var.project_id
}
