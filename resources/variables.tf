variable "project_id" {
  description = "Dedicated Google Maps project ID. Keep this SEPARATE from the production GKE/CloudSQL project for stability and quota isolation."
  type        = string
}

variable "ios_bundle_ids" {
  description = "iOS bundle identifiers allowed to use the iOS key."
  type        = list(string)
  default     = ["com.example"]
}

variable "android_applications" {
  description = <<-EOT
    Android apps allowed to use the Android key. Each entry is the app package
    name plus the SHA-1 fingerprint of its signing certificate. Get the SHA-1 via:
      keytool -list -v -keystore my.keystore -alias my-alias
  EOT
  type = list(object({
    package_name     = string
    sha1_fingerprint = string
  }))
  default = [{
    package_name     = "com.example"
    sha1_fingerprint = "DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09"
  }]
}

variable "website_referrers" {
  description = "HTTP referrer patterns allowed to use the website key. Use a /* suffix so every path on the site matches."
  type        = list(string)
  default     = ["www.example.com/*"]
}

variable "website_api_services" {
  description = <<-EOT
    API restriction for the website key. NOTE: the source documentation did not
    include an API-restriction screenshot for the website key, so this defaults
    to the typical browser Maps services. Adjust to match your actual usage.
  EOT
  type        = list(string)
  default = [
    "maps-backend.googleapis.com",        # Maps JavaScript API
    "static-maps-backend.googleapis.com", # Maps Static API
  ]
}

variable "backend_allowed_ips" {
  description = <<-EOT
    IPv4/IPv6 addresses or CIDR subnets allowed to use the backend key.
    In the source docs this was the VPC IPv6 subnet (redacted, e.g. fda...de7::/96)
    obtained from Google Cloud support. Provide your real value via tfvars.
  EOT
  type        = list(string)
}
