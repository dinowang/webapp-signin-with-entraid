output "website_url" {
  description = "The URL to the App Service"
  value       = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
}

output "zipdeploy_url" {
  description = "The URL to use for Zip Deployments to the App Service"
  value       = "https://web-${var.codename}-${random_id.codename_suffix.hex}.scm.azurewebsites.net/ZipDeployUI"
}

output "resource_group" {
  description = "The name of the Resource Group"
  value       = azurerm_resource_group.default.name
}

output "app_name" {
  description = "The name of the App Service"
  value       = "web-${var.codename}-${random_id.codename_suffix.hex}"
}