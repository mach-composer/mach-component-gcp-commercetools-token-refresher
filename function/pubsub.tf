resource "google_pubsub_topic" "notification" {
  name = "${var.site}-ctp-token-rotator"
}

resource "google_project_service_identity" "secretmanager" {
  provider = google-beta
  project  = data.google_project.current.project_id
  service  = "secretmanager.googleapis.com"
}

resource "google_pubsub_topic_iam_binding" "binding" {
  project = data.google_project.current.project_id
  topic   = google_pubsub_topic.notification.name
  role    = "roles/pubsub.publisher"
  members = [

    "serviceAccount:${google_project_service_identity.secretmanager.email}"
  ]
}


