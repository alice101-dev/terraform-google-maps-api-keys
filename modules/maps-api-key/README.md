# Module: maps-api-key

Creates a single **Google Maps API key** (`google_apikeys_key`) with:

- an **application restriction** (choose one): iOS bundle IDs, HTTP referrers, server IPs, or Android apps, and
- an **API restriction** (`api_targets`) limiting which services the key may call.

> GCP allows only **one** application restriction per key. The module has a
> precondition that fails the plan if you set more than one.

## Usage

```hcl
module "ios_key" {
  source = "../modules/maps-api-key"

  name         = "maps-ios-key"
  display_name = "Google Maps - iOS"
  project      = "my-maps-project"

  allowed_bundle_ids = ["com.example"]
  api_services = [
    "maps-backend.googleapis.com",        # Maps JavaScript API
    "static-maps-backend.googleapis.com", # Maps Static API
    "maps-ios-backend.googleapis.com",    # Maps SDK for iOS
  ]
}
```

## Canonical Maps service names

| Console name          | Service (`api_services` / enable value)     |
|-----------------------|---------------------------------------------|
| Maps JavaScript API   | `maps-backend.googleapis.com`               |
| Maps Static API       | `static-maps-backend.googleapis.com`        |
| Maps SDK for iOS      | `maps-ios-backend.googleapis.com`           |
| Maps SDK for Android  | `maps-android-backend.googleapis.com`       |
| Geocoding API         | `geocoding-backend.googleapis.com`          |
| Distance Matrix API   | `distance-matrix-backend.googleapis.com`    |
| Places API            | `places-backend.googleapis.com`             |

## Inputs

| Name                   | Type           | Default   | Description |
|------------------------|----------------|-----------|-------------|
| `name`                 | string         | —         | Key resource name (RFC-1034). |
| `display_name`         | string         | `null`    | Display name in console. |
| `project`              | string         | —         | Owning project ID. |
| `api_services`         | list(string)   | `[]`      | Allowed service names (API restriction). |
| `allowed_bundle_ids`   | list(string)   | `[]`      | iOS app restriction. |
| `allowed_referrers`    | list(string)   | `[]`      | Website (HTTP referrer) restriction. |
| `allowed_ips`          | list(string)   | `[]`      | Server/backend IP restriction. |
| `android_applications` | list(object)   | `[]`      | Android app restriction. |
| `deletion_policy`      | string         | `DELETE`  | DELETE / PREVENT / ABANDON. |

## Outputs

| Name         | Description |
|--------------|-------------|
| `id`         | Full resource id. |
| `name`       | Short resource name. |
| `uid`        | UUID4 id. |
| `key_string` | Encrypted key string (**sensitive**). |
