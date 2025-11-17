output "website_url" {
  description = "The URL to the App Service"
  value       = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
}

output "zipdeploy_url" {
  description = "The URL to use for Zip Deployments to the App Service"
  value       = "https://web-${var.codename}-${random_id.codename_suffix.hex}.scm.azurewebsites.net/ZipDeployUI"
}
