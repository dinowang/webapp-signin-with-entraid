resource "azurerm_application_insights" "default" {
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  workspace_id        = azurerm_log_analytics_workspace.default.id
  name                = "apm-${var.codename}-${random_id.codename_suffix.hex}"
  application_type    = "web"
}

resource "azurerm_monitor_smart_detector_alert_rule" "example" {
  resource_group_name = azurerm_resource_group.default.name
  scope_resource_ids  = [azurerm_application_insights.default.id]
  name                = "apm-${var.codename}-${random_id.codename_suffix.hex}-condition"
  severity            = "Sev0"
  frequency           = "PT1M"
  detector_type       = "FailureAnomaliesDetector"

  action_group {
    ids = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_action_group" "default" {
  resource_group_name = azurerm_resource_group.default.name
  name                = "apm-${var.codename}-${random_id.codename_suffix.hex}-action"
  short_name          = var.codename
}
