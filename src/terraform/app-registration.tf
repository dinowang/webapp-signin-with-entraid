# resource "azuread_application_registration" "default" {
#   display_name     = "sp-${var.codename}-${random_id.codename_suffix.hex}"
#   description      = "sp-${var.codename}-${random_id.codename_suffix.hex}"
#   sign_in_audience = "AzureADMultipleOrgs"
#   #sign_in_audience = "AzureADMyOrg"

#   homepage_url          = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
#   logout_url            = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/signout-oidc"
#   marketing_url         = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
#   privacy_statement_url = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/privacy"
#   support_url           = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
#   terms_of_service_url  = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
# }

# resource "azuread_application_redirect_uris" "default_web" {
#   application_id = azuread_application_registration.default.id
#   type           = "Web"

#   redirect_uris = [
#     "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/signin-oidc",
#   ]
# }

# resource "azuread_application_federated_identity_credential" "default" {
#   application_id = azuread_application_registration.default.id
#   display_name   = azurerm_user_assigned_identity.default.name
#   description    = azurerm_user_assigned_identity.default.name
#   issuer         = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
#   subject        = azurerm_user_assigned_identity.default.principal_id
#   audiences      = ["api://AzureADTokenExchange"]
# }


resource "azuread_application" "default" {
  display_name     = "sp-${var.codename}-${random_id.codename_suffix.hex}"
  description      = "sp-${var.codename}-${random_id.codename_suffix.hex}"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMultipleOrgs"
  #sign_in_audience = "AzureADMyOrg"

  marketing_url         = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
  privacy_statement_url = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/privacy"
  support_url           = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
  terms_of_service_url  = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"

  web {
    homepage_url = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/"
    logout_url   = "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/signout-oidc"

    redirect_uris = [
      "https://web-${var.codename}-${random_id.codename_suffix.hex}.azurewebsites.net/signin-oidc"
    ]
  }
}

resource "time_sleep" "wait_application" {
  create_duration = "60s" # 視情況調整 15~60s
  
  depends_on      = [azuread_application.default]
}

resource "azuread_application_federated_identity_credential" "default" {
  application_id = azuread_application.default.id
  display_name   = azurerm_user_assigned_identity.default.name
  description    = azurerm_user_assigned_identity.default.name
  issuer         = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
  subject        = azurerm_user_assigned_identity.default.principal_id
  audiences      = ["api://AzureADTokenExchange"]

  depends_on = [ time_sleep.wait_application ]
}
