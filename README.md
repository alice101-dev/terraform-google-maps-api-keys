# GCP Google Maps API Key Restrictions — Terraform

[![CI](https://github.com/alice101-dev/terraform-google-maps-api-keys/actions/workflows/ci.yml/badge.svg)](https://github.com/alice101-dev/terraform-google-maps-api-keys/actions/workflows/ci.yml)

Infrastructure-as-Code for provisioning **restricted Google Maps API keys** on GCP.
Locking down each key with an *application* restriction and an *API* restriction helps
prevent unauthorized use and quota theft if a key ever leaks.

This repo codifies, with Terraform, the four key-restriction patterns used for a typical
Google Maps deployment:

| Platform    | Application restriction         | API restriction |
|-------------|---------------------------------|-----------------|
| **iOS**     | iOS app bundle ID               | Maps JavaScript API, Maps Static API, Maps SDK for iOS |
| **Android** | App package + SHA-1 cert        | Maps JavaScript API, Maps Static API, Maps SDK for Android |
| **Website** | HTTP referrer (domain)          | Maps JavaScript API, Maps Static API |
| **Backend** | Server IP (VPC IPv6 subnet)     | Geocoding API, Distance Matrix API, Places API |

> **Design note:** Do not share a Google Maps API key with the production project used for
> GKE, CloudSQL, etc. Create a **dedicated project** for Maps for stability and quota
> isolation. `var.project_id` in this config is that dedicated project.

## Highlights

- **Reusable module** (`modules/maps-api-key`) — one `google_apikeys_key` with a dynamic
  restriction block that adapts to whichever application restriction you pass.
- **Fail-fast validation** — a precondition rejects the plan if you set more than one
  application restriction (GCP allows only one per key).
- **Automatic API enablement** — every Maps service used by any key, plus the API Keys API
  itself, is enabled via `google_project_service`.
- **Secrets stay sensitive** — key strings are marked `sensitive` in outputs.
- Pinned to `hashicorp/google >= 7.0, < 8.0`, Terraform `>= 1.5.0`.

## Repository layout

```
.
├── .github/
│   └── workflows/
│       └── ci.yml             # fmt + validate + Checkov on every push/PR
├── modules/
│   └── maps-api-key/          # Reusable module: one restricted google_apikeys_key
│       ├── main.tf            # Key + dynamic restriction blocks + single-restriction precondition
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── resources/                 # Root config: the iOS / Android / website / backend keys
│   ├── providers.tf           # hashicorp/google >= 7.0, < 8.0
│   ├── main.tf                # 4 module instances + google_project_service (API enablement)
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars       # example values — edit before applying
│   └── backend.tf.example     # GCS remote-state template
├── .gitignore
└── README.md
```

## Usage

```bash
cd resources
# edit terraform.tfvars to set project_id + backend_allowed_ips
terraform init
terraform plan
terraform apply
```

Required inputs (`resources/terraform.tfvars`):

| Variable              | Description |
|-----------------------|-------------|
| `project_id`          | Dedicated Maps project (separate from production). |
| `backend_allowed_ips` | VPC IPv6 subnet allowed for the backend key (ask Google Cloud support for your VPC IPv6, e.g. `fda…::/96`). |
| `ios_bundle_ids`      | iOS bundle IDs (default `com.example`). |
| `android_applications`| Android apps: `package_name` + `sha1_fingerprint` of the signing cert. |
| `website_referrers`   | Website referrer pattern(s) (default `www.example.com/*`). |

The API Keys API (`apikeys.googleapis.com`) and every Maps service used by the keys are
enabled automatically via `google_project_service`.

## Testing & security scanning

Every push and pull request runs through [GitHub Actions](.github/workflows/ci.yml):

```bash
terraform fmt -check -recursive          # formatting
terraform init -backend=false && terraform validate   # schema validation (in resources/)
checkov -d . --framework terraform       # static security analysis
```

Checkov reports no findings. (Note: Checkov has no built-in policies for
`google_apikeys_key` yet, so the scan mainly guards the repo against future
resources; `fmt` + `validate` do the heavy lifting here.)

## Remote state (GCS backend)

State is **local by default** so the repo runs with no extra setup. For team or CI use,
switch to a GCS backend for remote state and state locking.

The state bucket must exist **before** `terraform init` — Terraform cannot create the
bucket that holds its own state, and backend blocks cannot use variables (the bucket name
must be a literal). Create it once:

```bash
PROJECT_ID="example-google-maps"
BUCKET="${PROJECT_ID}-tf-state"   # bucket names are globally unique

gsutil mb -p "$PROJECT_ID" -l US -b on "gs://${BUCKET}"
gsutil versioning set on "gs://${BUCKET}"   # keep state history / allow rollback
```

Then enable the backend and migrate the existing local state:

```bash
cp backend.tf.example backend.tf   # then edit backend.tf, set your bucket name
terraform init                     # prompts to migrate local state -> GCS
```

See [`resources/backend.tf.example`](resources/backend.tf.example) for the block.

---

## The four keys

### iOS key

Application restriction → **iOS apps**, bundle ID `com.example`.
API restriction → Maps JavaScript API, Maps Static API, Maps SDK for iOS.

```hcl
module "ios_key" {
  source             = "../modules/maps-api-key"
  name               = "maps-ios-key"
  project            = var.project_id
  allowed_bundle_ids = ["com.example"]
  api_services = [
    "maps-backend.googleapis.com",        # Maps JavaScript API
    "static-maps-backend.googleapis.com", # Maps Static API
    "maps-ios-backend.googleapis.com",    # Maps SDK for iOS
  ]
}
```

### Android key

Application restriction → **Android apps**, package name + SHA-1 of the signing cert.
API restriction → Maps JavaScript API, Maps Static API, Maps SDK for Android.

```hcl
module "android_key" {
  source  = "../modules/maps-api-key"
  name    = "maps-android-key"
  project = var.project_id
  android_applications = [{
    package_name     = "com.example"
    sha1_fingerprint = "DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09"
  }]
  api_services = [
    "maps-backend.googleapis.com",         # Maps JavaScript API
    "static-maps-backend.googleapis.com",  # Maps Static API
    "maps-android-backend.googleapis.com", # Maps SDK for Android
  ]
}
```

### Website key

Application restriction → **HTTP referrers**, allow only your domain
(use the `/*` suffix so every path on the site matches).
API restriction → Maps JavaScript API, Maps Static API.

```hcl
module "website_key" {
  source            = "../modules/maps-api-key"
  name              = "maps-website-key"
  project           = var.project_id
  allowed_referrers = ["www.example.com/*"]
  api_services = [
    "maps-backend.googleapis.com",        # Maps JavaScript API
    "static-maps-backend.googleapis.com", # Maps Static API
  ]
}
```

### Backend key

Application restriction → **IP addresses**. Allow only the GCP VPC (ask Google Cloud
support for an IPv6 subnet in your VPC).
API restriction → Geocoding API, Distance Matrix API, Places API.

```hcl
module "backend_key" {
  source       = "../modules/maps-api-key"
  name         = "maps-backend-key"
  project      = var.project_id
  allowed_ips  = var.backend_allowed_ips # VPC IPv6 subnet, e.g. fda…::/96
  api_services = [
    "geocoding-backend.googleapis.com",       # Geocoding API
    "distance-matrix-backend.googleapis.com", # Distance Matrix API
    "places-backend.googleapis.com",          # Places API
  ]
}
```

Because the backend key is IP-restricted to the VPC, calling it from outside GCP is
rejected with `REQUEST_DENIED`:

```jsonc
// curl from an unauthorized IP:
{
   "error_message" : "This IP, site or mobile application is not authorized to use this API key. Request received from IP address 106.250.163.24, with empty referer",
   "predictions" : [],
   "status" : "REQUEST_DENIED"
}
```

---

## Canonical Maps service names

Use these values in `api_services` and for API enablement:

| Console name          | Service name                             |
|-----------------------|------------------------------------------|
| Maps JavaScript API   | `maps-backend.googleapis.com`            |
| Maps Static API       | `static-maps-backend.googleapis.com`     |
| Maps SDK for iOS      | `maps-ios-backend.googleapis.com`        |
| Maps SDK for Android  | `maps-android-backend.googleapis.com`    |
| Geocoding API         | `geocoding-backend.googleapis.com`       |
| Distance Matrix API   | `distance-matrix-backend.googleapis.com` |
| Places API            | `places-backend.googleapis.com`          |

## Monitoring

Usage per API is visible in the [Google Maps Platform dashboard](https://console.cloud.google.com/google/maps-apis/metrics)
and in Cloud Monitoring, letting you spot anomalous traffic per key.
