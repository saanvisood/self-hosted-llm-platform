variable "open_webui_user" {
  description = "Username to access Open WebUI"
  default     = "admin@demo.gs"
}

variable "openai_base" {
  description = "Optional base URL to use OpenAI API with Open WebUI"
  default     = ""
}

variable "openai_key" {
  description = "Optional API key to use OpenAI API with Open WebUI"
  default     = ""
  sensitive   = true
}

variable "ollama_model" {
  description = "Model pulled into the bundled Ollama at boot"
  default     = "llama3.2:1b"
}

variable "lockdown_egress" {
  description = "Remove private instance internet access after bootstrap"
  type        = bool
  default     = false
}

variable "admin_cidr" {
  description = "IP for bastion SSH"
  type        = string
  validation {
    # Checking that value is well-formed AND not 0.0.0.0/0
    condition     = can(cidrhost(var.admin_cidr, 0) && var.admin_cidr != "0.0.0.0/0")
    error_message = "Use a specific CIDR"
  }
}

variable "alert_email" {
  description = "SNS subscription and budget notifications"
  type        = string
}
