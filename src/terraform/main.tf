terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  features {
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "random" {}

resource "random_id" "codename_suffix" {
  byte_length = 3
}

data "azuread_client_config" "current" {}

resource "azuread_application_registration" "default" {
  display_name     = "sp-${var.codename}-${random_id.codename_suffix.hex}"
  description      = "sp-${var.codename}-${random_id.codename_suffix.hex}"
  sign_in_audience = "AzureADMultipleOrgs"
  #sign_in_audience = "AzureADMyOrg"

  homepage_url          = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
  logout_url            = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/logout"
  marketing_url         = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
  privacy_statement_url = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/privacy"
  support_url           = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/support"
  terms_of_service_url  = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/terms"
}

resource "azuread_application_federated_identity_credential" "default" {
  application_id = azuread_application_registration.default.id
  display_name   = azurerm_user_assigned_identity.default.name
  description    = azurerm_user_assigned_identity.default.name
  issuer         = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
  subject        = azurerm_user_assigned_identity.default.principal_id
  audiences      = ["api://AzureADTokenExchange"]
}

resource "azuread_application_redirect_uris" "default_web" {
  application_id = azuread_application_registration.default.id
  type           = "Web"

  redirect_uris = [
    "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/signin-oidc",
  ]
}

resource "azurerm_resource_group" "default" {
  location = var.location
  name     = "rg-${var.codename}-${random_id.codename_suffix.hex}"
}

resource "azurerm_user_assigned_identity" "default" {
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  name                = "mi-${var.codename}-${random_id.codename_suffix.hex}"
}

resource "azurerm_application_insights" "default" {
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  name                = "apm-${var.codename}-${random_id.codename_suffix.hex}"
  application_type    = "web"
}

resource "azurerm_monitor_smart_detector_alert_rule" "example" {
  resource_group_name = azurerm_resource_group.default.name
  scope_resource_ids  = [azurerm_application_insights.default.id]
  name                = "sdar-${var.codename}-${random_id.codename_suffix.hex}"
  severity            = "Sev0"
  frequency           = "PT1M"
  detector_type       = "FailureAnomaliesDetector"

  action_group {
    ids = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_action_group" "default" {
  resource_group_name = azurerm_resource_group.default.name
  name                = "ag-${var.codename}-${random_id.codename_suffix.hex}"
  short_name          = "ag-${var.codename}"
}

resource "azurerm_service_plan" "default" {
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  name                = "plan-${var.codename}-${random_id.codename_suffix.hex}"
  os_type             = var.appservice_os
  sku_name            = var.appservice_sku
}

resource "azurerm_linux_web_app" "default" {
  location            = azurerm_service_plan.default.location
  resource_group_name = azurerm_resource_group.default.name
  service_plan_id     = azurerm_service_plan.default.id
  name                = "web-${var.codename}-${random_id.codename_suffix.hex}"
  count               = var.appservice_os == "Linux" ? 1 : 0

  site_config {
    always_on = var.appservice_sku != "F1" && var.appservice_sku != "D1" ? true : false
  }

  logs {
    detailed_error_messages = false
    failed_request_tracing  = false  

    application_logs {
      file_system_level = "Verbose"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.default.id]
  }

  app_settings = {
    "ApplicationInsights__ConnectionString"                  = azurerm_application_insights.default.connection_string    
    "AzureAD__Instance"                                      = "https://login.microsoftonline.com/",
    "AzureAD__TenantId"                                      = var.tenant_id,
    "AzureAD__ClientId"                                      = azuread_application_registration.default.client_id,
    "AzureAD__ClientCredentials__0__SourceType"              = "SignedAssertionFromManagedIdentity",
    "AzureAD__ClientCredentials__0__ManagedIdentityClientId" = azurerm_user_assigned_identity.default.client_id
  }
}

resource "azurerm_windows_web_app" "default" {
  location            = azurerm_service_plan.default.location
  resource_group_name = azurerm_resource_group.default.name
  service_plan_id     = azurerm_service_plan.default.id
  name                = "web-${var.codename}-${random_id.codename_suffix.hex}"
  count               = var.appservice_os == "Windows" ? 1 : 0

  site_config {
    always_on = var.appservice_sku != "F1" && var.appservice_sku != "D1" ? true : false

    application_stack {
      current_stack = "dotnetcore"
      dotnet_version = "v8.0"
    }  
  }

  logs {
    detailed_error_messages = false
    failed_request_tracing  = false  

    application_logs {
      file_system_level = "Verbose"
    }
  }
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.default.id]
  }

  app_settings = {
    "ApplicationInsights__ConnectionString"                  = azurerm_application_insights.default.connection_string    
    "AzureAD__Instance"                                      = "https://login.microsoftonline.com/",
    "AzureAD__TenantId"                                      = var.tenant_id,
    "AzureAD__ClientId"                                      = azuread_application_registration.default.client_id,
    "AzureAD__ClientCredentials__0__SourceType"              = "SignedAssertionFromManagedIdentity",
    "AzureAD__ClientCredentials__0__ManagedIdentityClientId" = azurerm_user_assigned_identity.default.client_id
  }
}

