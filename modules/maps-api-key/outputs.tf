output "id" {
  description = "Full resource identifier of the API key."
  value       = google_apikeys_key.this.id
}

output "name" {
  description = "Short resource name of the API key."
  value       = google_apikeys_key.this.name
}

output "uid" {
  description = "Unique UUID4 id of the key."
  value       = google_apikeys_key.this.uid
}

output "key_string" {
  description = "The encrypted key string. Handle as a secret."
  value       = google_apikeys_key.this.key_string
  sensitive   = true
}
