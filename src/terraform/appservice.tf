
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
    "AzureAD__ClientId"                                      = azuread_application.default.client_id,
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
      current_stack  = "dotnetcore"
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
    "AzureAD__ClientId"                                      = azuread_application.default.client_id,
    "AzureAD__ClientCredentials__0__SourceType"              = "SignedAssertionFromManagedIdentity",
    "AzureAD__ClientCredentials__0__ManagedIdentityClientId" = azurerm_user_assigned_identity.default.client_id
  }

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack
    ]
  }
}
