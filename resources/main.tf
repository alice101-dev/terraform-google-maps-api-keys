locals {
  # Canonical service names -> console display names, for readability.
  maps_js       = "maps-backend.googleapis.com"            # Maps JavaScript API
  maps_static   = "static-maps-backend.googleapis.com"     # Maps Static API
  maps_ios      = "maps-ios-backend.googleapis.com"        # Maps SDK for iOS
  maps_android  = "maps-android-backend.googleapis.com"    # Maps SDK for Android
  geocoding     = "geocoding-backend.googleapis.com"       # Geocoding API
  distance_mtrx = "distance-matrix-backend.googleapis.com" # Distance Matrix API
  places        = "places-backend.googleapis.com"          # Places API

  ios_api_services     = [local.maps_js, local.maps_static, local.maps_ios]
  android_api_services = [local.maps_js, local.maps_static, local.maps_android]
  backend_api_services = [local.geocoding, local.distance_mtrx, local.places]

  # Every Maps service used by any key, plus the API Keys API itself. Enabled once.
  services_to_enable = toset(concat(
    [local.maps_js, local.maps_static, local.maps_ios, local.maps_android, local.geocoding, local.distance_mtrx, local.places],
    var.website_api_services,
    ["apikeys.googleapis.com"],
  ))
}

# Enable the required APIs on the dedicated Maps project.
resource "google_project_service" "maps" {
  for_each = local.services_to_enable

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# --- iOS key: bundle com.example, Maps JS + Maps Static + Maps SDK for iOS ---
module "ios_key" {
  source = "../modules/maps-api-key"

  name         = "maps-ios-key"
  display_name = "Google Maps - iOS"
  project      = var.project_id

  allowed_bundle_ids = var.ios_bundle_ids
  api_services       = local.ios_api_services

  depends_on = [google_project_service.maps]
}

# --- Android key: package + SHA-1 signing cert, Maps JS + Maps Static + Maps SDK for Android ---
module "android_key" {
  source = "../modules/maps-api-key"

  name         = "maps-android-key"
  display_name = "Google Maps - Android"
  project      = var.project_id

  android_applications = var.android_applications
  api_services         = local.android_api_services

  depends_on = [google_project_service.maps]
}

# --- Website key: HTTP referrer www.example.com ---
module "website_key" {
  source = "../modules/maps-api-key"

  name         = "maps-website-key"
  display_name = "Google Maps - Website"
  project      = var.project_id

  allowed_referrers = var.website_referrers
  api_services      = var.website_api_services

  depends_on = [google_project_service.maps]
}

# --- Backend key: VPC IPv6 subnet, Geocoding + Distance Matrix + Places ---
module "backend_key" {
  source = "../modules/maps-api-key"

  name         = "maps-backend-key"
  display_name = "Google Maps - Backend"
  project      = var.project_id

  allowed_ips  = var.backend_allowed_ips
  api_services = local.backend_api_services

  depends_on = [google_project_service.maps]
}
