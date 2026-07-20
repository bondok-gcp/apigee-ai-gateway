variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""
}

variable "enable_gemini" {
  description = "Enable Gemini AI Proxy"
  type        = bool
  default     = true
}

variable "enable_claude" {
  description = "Enable Claude AI Proxy"
  type        = bool
  default     = true
}
