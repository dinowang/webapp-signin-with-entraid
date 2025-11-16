variable "tenant_id" {
  description = "The Tenant ID for the Azure Active Directory."
  type        = string
}

variable "subscription_id" {
  description = "The Subscription ID for the Azure subscription."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
}

variable "codename" {
  description = "The codename of the project."
  type        = string
}

variable "appservice_os" {
  description = "The operating system for the App Service Plan."
  type        = string
  default     = "Linux"
}

variable "appservice_sku" {
  description = "The SKU for the App Service Plan."
  type        = string
  default     = "F1"
}