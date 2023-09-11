
resource "google_service_account" "default" {
  account_id   = substr("${var.site}-ctp-token-rotator", 0, 24)
  display_name = "Test Service Account"
}

resource "google_cloudfunctions2_function" "rotator" {
  name        = "${var.site}-ctp-token-rotator"
  description = "Refresh commercetools token"
  location    = data.google_client_config.current.region

  service_config {
    max_instance_count = 3
    min_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      SERVICE_CONFIG_TEST = "config_test"
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.default.email
  }

  build_config {
    runtime     = "nodejs20"
    entry_point = "rotateSecret"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_archive.name
      }
    }
  }

  event_trigger {
    trigger_region = data.google_client_config.current.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.notification.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
