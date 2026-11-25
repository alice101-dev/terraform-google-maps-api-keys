output "ios_key_id" {
  description = "Resource id of the iOS Maps key."
  value       = module.ios_key.id
}

output "android_key_id" {
  description = "Resource id of the Android Maps key."
  value       = module.android_key.id
}

output "website_key_id" {
  description = "Resource id of the website Maps key."
  value       = module.website_key.id
}

output "backend_key_id" {
  description = "Resource id of the backend Maps key."
  value       = module.backend_key.id
}

output "key_strings" {
  description = "Encrypted key strings for all keys. Treat as secrets."
  value = {
    ios     = module.ios_key.key_string
    android = module.android_key.key_string
    website = module.website_key.key_string
    backend = module.backend_key.key_string
  }
  sensitive = true
}
