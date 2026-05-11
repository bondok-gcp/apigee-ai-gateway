/* Variables */

variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "region" {
  description = "GCP region for the Apigee runtime & analytics data (see https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli)."
  type        = string
}

variable "apigee_type" {
  description = "The Apigee billing type, either EVALUATION, PAYG or SUBSCRIPTION."
  type        = string
  default     = "EVALUATION"
}

locals {
  gcp_services = [
    "apigee.googleapis.com",
    "apihub.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "aiplatform.googleapis.com"
  ]
}

/* Project */

resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.gcp_services)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "auto_vpc" {
  name                    = "default"
  auto_create_subnetworks = true
  routing_mode            = "REGIONAL"
  depends_on              = [google_project_service.enabled_apis]
}

resource "google_compute_global_address" "external_vip" {
  name         = "apigee-external-vip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  depends_on   = [google_project_service.enabled_apis]
}

resource "google_compute_managed_ssl_certificate" "nip_io_cert" {
  name = "apigee-nip-io-cert"

  managed {
    domains = ["${google_compute_global_address.external_vip.address}.nip.io"]
  }
}

/* Apigee */

resource "google_apigee_organization" "apigee_org" {
  project_id          = var.project_id
  analytics_region    = var.region
  disable_vpc_peering = true
  runtime_type        = "CLOUD"
  billing_type        = var.apigee_type
  depends_on          = [google_project_service.enabled_apis]
}

resource "google_apigee_instance" "apigee" {
  name                 = "apigee-psc-instance"
  location             = var.region
  org_id               = google_apigee_organization.apigee_org.id
  consumer_accept_list = [var.project_id]
}

resource "google_compute_region_network_endpoint_group" "apigee_psc_neg" {
  name                  = "apigee-psc-neg"
  region                = var.region
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = google_apigee_instance.apigee.service_attachment
}

resource "google_compute_backend_service" "apigee_backend" {
  name                  = "apigee-psc-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group = google_compute_region_network_endpoint_group.apigee_psc_neg.id
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "apigee-psc-url-map"
  default_service = google_compute_backend_service.apigee_backend.id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "apigee-psc-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.nip_io_cert.id]
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = "apigee-psc-forwarding-rule"
  ip_address            = google_compute_global_address.external_vip.address
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_apigee_environment" "dev_env" {
  name         = "dev"
  org_id       = google_apigee_organization.apigee_org.id
  display_name = "Development Environment"
  description  = "Development environment for API proxy deployments"
}

resource "google_apigee_envgroup" "dev_envgroup" {
  name      = "dev"
  org_id    = google_apigee_organization.apigee_org.id
  hostnames = ["${google_compute_global_address.external_vip.address}.nip.io"]
}

resource "google_apigee_envgroup_attachment" "dev_envgroup_attachment" {
  envgroup_id = google_apigee_envgroup.dev_envgroup.id
  environment = google_apigee_environment.dev_env.name
}

resource "google_apigee_instance_attachment" "dev_instance_attachment" {
  instance_id = google_apigee_instance.apigee.id
  environment = google_apigee_environment.dev_env.name
}

output "apigee_endpoint_url" {
  value       = "https://${google_compute_global_address.external_vip.address}.nip.io"
  description = "Your public secure Apigee API endpoint."
}

/* API Hub */

resource "google_apihub_host_project_registration" "apihub_host_project" {
  project                      = var.project_id
  location                     = var.region
  host_project_registration_id = var.project_id
  gcp_project                  = "projects/${var.project_id}"

  depends_on = [google_project_service.enabled_apis, google_apigee_instance.apigee]
}

resource "google_project_service_identity" "apihub_service_identity" {
  provider = google-beta
  project  = var.project_id
  service  = "apihub.googleapis.com"
}

resource "google_project_iam_member" "apihub_service_identity_permission" {
  provider = google-beta
  project  = var.project_id
  for_each = toset([
    "roles/apihub.admin",
    "roles/apihub.runtimeProjectServiceAgent"
  ])
  role       = each.key
  member     = "serviceAccount:${google_project_service_identity.apihub_service_identity.email}"
  depends_on = [google_project_service_identity.apihub_service_identity]
}

resource "google_apihub_api_hub_instance" "apihub-instance" {
  provider = google-beta
  project  = var.project_id
  location = var.region
  config {
    disable_search  = false
    vertex_location = "eu"
  }
  depends_on = [google_apihub_host_project_registration.apihub_host_project]
}
