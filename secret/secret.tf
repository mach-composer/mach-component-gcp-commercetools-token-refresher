data "google_project" "current" {}

data "google_pubsub_topic" "primary" {
  name = "${var.site}-ctp-token-rotator"
}

data "google_service_account" "default" {
  account_id = substr("${var.site}-ctp-token-rotator", 0, 24)
}


resource "google_secret_manager_secret" "credentials" {
  secret_id = "${var.site}-${var.name}-ct-credentials"

  labels = var.labels

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "credentials" {
  secret = google_secret_manager_secret.credentials.id
  secret_data = jsonencode({
    clientId     = commercetools_api_client.main.id
    clientSecret = commercetools_api_client.main.secret
    clientScopes = var.scopes
  })
}

resource "google_secret_manager_secret" "token" {
  secret_id = "${var.site}-${var.name}-ct-access-token"

  labels = var.labels

  replication {
    automatic = true
  }

  rotation {
    rotation_period    = "86400s"                    // Rotate every day
    next_rotation_time = timeadd(timestamp(), "10m") // needs to be 5 minutes in the future
  }

  topics {
    name = data.google_pubsub_topic.primary.id
  }

  lifecycle {
    ignore_changes = [
      rotation[0].next_rotation_time
    ]
  }
}

# Give access to the rotate function to read the credentials
resource "google_secret_manager_secret_iam_member" "credentials" {
  secret_id = google_secret_manager_secret.credentials.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_service_account.default.email}"
}

# Give access to the rotate function to write the tokens
resource "google_secret_manager_secret_iam_member" "token" {
  secret_id = google_secret_manager_secret.token.id
  role      = "roles/secretmanager.secretVersionManager"
  member    = "serviceAccount:${data.google_service_account.default.email}"
}


