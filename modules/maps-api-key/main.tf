terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0, < 8.0"
    }
  }
}

locals {
  # Exactly one application restriction may be set per key.
  restriction_count = length([
    for enabled in [
      length(var.allowed_bundle_ids) > 0,
      length(var.allowed_referrers) > 0,
      length(var.allowed_ips) > 0,
      length(var.android_applications) > 0,
    ] : enabled if enabled
  ])
}

# Fail fast if more than one application restriction type is configured:
# GCP allows only a single application restriction per API key.
resource "terraform_data" "validate_single_restriction" {
  lifecycle {
    precondition {
      condition     = local.restriction_count <= 1
      error_message = "Only one application restriction (bundle IDs, referrers, IPs, or Android apps) may be set per API key."
    }
  }
}

resource "google_apikeys_key" "this" {
  name            = var.name
  display_name    = var.display_name
  project         = var.project
  deletion_policy = var.deletion_policy

  restrictions {
    dynamic "api_targets" {
      for_each = var.api_services
      content {
        service = api_targets.value
      }
    }

    dynamic "ios_key_restrictions" {
      for_each = length(var.allowed_bundle_ids) > 0 ? [1] : []
      content {
        allowed_bundle_ids = var.allowed_bundle_ids
      }
    }

    dynamic "browser_key_restrictions" {
      for_each = length(var.allowed_referrers) > 0 ? [1] : []
      content {
        allowed_referrers = var.allowed_referrers
      }
    }

    dynamic "server_key_restrictions" {
      for_each = length(var.allowed_ips) > 0 ? [1] : []
      content {
        allowed_ips = var.allowed_ips
      }
    }

    dynamic "android_key_restrictions" {
      for_each = length(var.android_applications) > 0 ? [1] : []
      content {
        dynamic "allowed_applications" {
          for_each = var.android_applications
          content {
            package_name     = allowed_applications.value.package_name
            sha1_fingerprint = allowed_applications.value.sha1_fingerprint
          }
        }
      }
    }
  }

  depends_on = [terraform_data.validate_single_restriction]
}
