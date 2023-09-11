data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/dist/index.zip"

  source {
    content  = file("${path.module}/src/index.js")
    filename = "index.js"
  }

  source {
    content  = file("${path.module}/src/package.json")
    filename = "package.json"
  }
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.site}-ctp-token-rotator"
  location = data.google_client_config.current.region

  labels = {
    function = "${var.site}-ctp-token-rotator"
  }
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "ctp-token-rotator-${filesha256(data.archive_file.function_zip.output_path)}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}
