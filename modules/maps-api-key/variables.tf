variable "name" {
  description = "Resource name of the API key. Lower-cased letters, digits and hyphens; must match [a-z]([a-z0-9-]{0,61}[a-z0-9])?."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "name must match the regex [a-z]([a-z0-9-]{0,61}[a-z0-9])? (RFC-1034)."
  }
}

variable "display_name" {
  description = "Human-readable display name shown in the GCP console."
  type        = string
  default     = null
}

variable "project" {
  description = "Project ID that owns the key. Use a project dedicated to Google Maps APIs (not the production GKE/CloudSQL project)."
  type        = string
}

variable "api_services" {
  description = <<-EOT
    Canonical service names this key is allowed to call (api_targets restriction).
    Leave empty to allow the key to call any API (NOT recommended).
    Example Maps service names:
      - maps-backend.googleapis.com            (Maps JavaScript API)
      - static-maps-backend.googleapis.com     (Maps Static API)
      - maps-ios-backend.googleapis.com        (Maps SDK for iOS)
      - maps-android-backend.googleapis.com    (Maps SDK for Android)
      - geocoding-backend.googleapis.com       (Geocoding API)
      - distance-matrix-backend.googleapis.com (Distance Matrix API)
      - places-backend.googleapis.com          (Places API)
  EOT
  type        = list(string)
  default     = []
}

# ---- Application restriction (choose at most ONE of the four below) ----

variable "allowed_bundle_ids" {
  description = "iOS bundle IDs allowed to use the key (iOS app restriction)."
  type        = list(string)
  default     = []
}

variable "allowed_referrers" {
  description = "HTTP referrer patterns (regex) allowed to use the key (website restriction)."
  type        = list(string)
  default     = []
}

variable "allowed_ips" {
  description = "Caller IPv4/IPv6 addresses or CIDR subnets allowed to use the key (server/backend restriction)."
  type        = list(string)
  default     = []
}

variable "android_applications" {
  description = "Android apps allowed to use the key (package_name + sha1_fingerprint)."
  type = list(object({
    package_name     = string
    sha1_fingerprint = string
  }))
  default = []
}

variable "deletion_policy" {
  description = "Deletion behaviour: DELETE, PREVENT, or ABANDON."
  type        = string
  default     = "DELETE"

  validation {
    condition     = contains(["DELETE", "PREVENT", "ABANDON"], var.deletion_policy)
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON."
  }
}
