# Dedicated Google Maps project (separate from the production GKE/CloudSQL project).
project_id = "example-google-maps"

# iOS app bundle identifiers.
ios_bundle_ids = ["com.example"]

# Android apps: package name + SHA-1 of the signing certificate.
# (SHA-1 below is a placeholder for this portfolio repo — use your real one.)
android_applications = [
  {
    package_name     = "com.example"
    sha1_fingerprint = "DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09"
  },
]

# Website HTTP referrers (/* suffix matches every path on the site).
website_referrers = ["www.example.com/*"]

# Backend / server key allowed IPs — the VPC IPv6 subnet obtained from Google
# Cloud support. Example value for this portfolio repo (no real credentials).
backend_allowed_ips = ["fda0:1234:5678:9abc::/96"]
