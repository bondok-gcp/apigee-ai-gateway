terraform {
  backend "gcs" {
    bucket = "bond-ai-gateway-demo-tfstate"
    prefix = "apigee-proxies"
  }
}
