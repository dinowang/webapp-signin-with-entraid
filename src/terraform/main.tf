terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  features {}
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "random" {}

resource "random_id" "codename_suffix" {
  byte_length = 3
}

data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  location = var.location
  name     = "rg-${var.codename}-${random_id.codename_suffix.hex}"
}

resource "azurerm_user_assigned_identity" "default" {
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  name                = "mi-${var.codename}-${random_id.codename_suffix.hex}"
}

resource "azurerm_log_analytics_workspace" "default" {
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  name                = "law-${var.codename}-${random_id.codename_suffix.hex}"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}