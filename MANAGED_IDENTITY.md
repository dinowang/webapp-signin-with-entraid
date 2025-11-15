# Web Applications Sign-in using Managed Identity

With credential-less authentication becoming more prevalent, Microsoft.Identity.Web now supports using Managed Identity as a credential source for web applications.

appsettings.json
```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "52......-....-....-....-..........0e",
    "ClientId": "99......-....-....-....-..........f8",
    "ClientCredentials": [
      {
        "SourceType": "SignedAssertionFromManagedIdentity",
        "ManagedIdentityClientId": "2c......-....-....-....-..........54"
      }
    ],
    "CallbackPath": "/signin-oidc"
  },
  ...      
}
```

References:
[Credentials are generalizing certificates. | Microsoft.Identity.Web v2.1.0](https://github.com/AzureAD/microsoft-identity-web/wiki/v2.0#credentials-are-generalizing-certificates)

## Details

Create WebApp and User Assigned Managed Identity
![](./media/mi-user-assigned-identity.png)

Associate User Assigned Managed Identity with WebApp
![](./media/mi-webapp-with-user-assigned-identity.png)

Create Service Principal and setup Authentication Redirect URIs for WebApp
![](./media/mi-serviceprincipal-authentication.png)

Create Federated Credentials for User Assigned Managed Identity
![](./media/mi-serviceprincipal-federated-credentials.png)

Setup appsettings.json for WebApp to use Managed Identity
![](./media/mi-appsettings-json.png)

Open WebApp and Sign-in with Managed Identity
![](./media/mi-user-signed-in.png)

