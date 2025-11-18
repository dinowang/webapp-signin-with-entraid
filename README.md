# Managed Identity Web App 入門指南

本方案示範如何以 **Managed Identity** 取代 client secret，讓 ASP.NET Core Web App 在 Azure 上以無機密（credential-less）的方式存取 Microsoft Entra ID。專案同時提供 Terraform 基礎建設程式碼與 GitHub Actions 工作流程，協助開發與營運團隊快速完成部署。

## 解決方案概觀
- **`src/aspnet`**：基於 [Azure-Samples/ms-identity-docs-code-dotnet](https://github.com/Azure-Samples/ms-identity-docs-code-dotnet/tree/main/web-app-aspnet) 修改，將 `Microsoft.Identity.Web` 的 `ClientCredentials` 設為 `SignedAssertionFromManagedIdentity`，並整合 Application Insights 與 `.env`/環境變數載入邏輯。
- **`src/terraform`**：使用 Terraform 建立資源群組、Log Analytics、Application Insights、App Service Plan、App Service（Windows/Linux 任選）、使用者指派 Managed Identity，以及對應的 Azure AD 應用程式與 Federated Credential，確保 Web App 可以代表使用者呼叫 Microsoft Graph。
- **GitHub Workflows**：`deploy.yml` 透過 OIDC 與 `azure/login@v2` 完成無密碼基礎建設部署與 Zip Deploy；`destroy.yml` 用於拆除資源。

## 目錄結構
```text
.
├── src/aspnet/        # ASP.NET Core 8.0 Razor Pages Web App（Managed Identity 登入）
├── src/terraform/     # Terraform 基礎建設程式碼
└── .github/workflows/ # 部署與拆除的 GitHub Actions
```

## 先決條件
- Azure 訂閱，並授權你可建立 App Service 與 Entra 應用程式。
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)、`.NET 8 SDK`、[Terraform 1.13+](https://developer.hashicorp.com/terraform/downloads)。
- 有權限建立並管理 User Assigned Managed Identity 與 Federated Credential。
- GitHub repository 若要使用 Actions，需具備可設定 `Environment` 與 `Repository secrets` 的權限。

## 應用程式設定
`src/aspnet/appsettings.json` 提供預設值，實際部署時請改以環境變數（或 `.env`）覆寫。

```jsonc
"AzureAd": {
  "Instance": "https://login.microsoftonline.com/",
  "TenantId": "<your-tenant-id>",
  "ClientId": "<web-app-client-id>",
  "ClientCredentials": [
    {
      "SourceType": "SignedAssertionFromManagedIdentity",
      "ManagedIdentityClientId": "<user-assigned-managed-identity-client-id>"
    }
  ],
  "CallbackPath": "/signin-oidc"
}
```

使用環境變數取代直接編輯 appsettings.json

- 本機測試  
  可以利用一個 `.env` 檔案：
  ```env
  AzureAD__ClientCredentials__0__ManagedIdentityClientId=<user-assigned-managed-identity-client-id>
  AzureAD__ClientCredentials__0__SourceType=SignedAssertionFromManagedIdentity
  AzureAD__ClientId=<service-principal-client-id>
  AzureAD__Instance=https://login.microsoftonline.com/
  AzureAD__TenantId=<your-tenant-id>
  AzureAD__CallbackPath=/signin-oidc
  ```

- 部署至 Azure App Service  
  使用 Terraform 部署則不需要調整 appsettings.json，Terraform 會在 App Service 中自動寫入上述設定。若需了解 Managed Identity 配置細節，請參考 `src/aspnet/MANAGED_IDENTITY.md`。

## 人工部署流程
1. **初始化 Terraform**
   ```bash
   cd src/terraform
   terraform init
   terraform plan \
     -var="tenant_id=<TENANT_ID>" \
     -var="subscription_id=<SUBSCRIPTION_ID>" \
     -var="location=<AZURE_REGION>" \
     -var="codename=<PROJECT_CODE>" \
     -var="appservice_os=Windows" \
     -var="appservice_sku=F1" \
     -out=tfplan
   terraform apply tfplan
   ```

2. **取得輸出資訊**
   ```bash
   terraform output -raw resource_group   # 後續 Zip Deploy 會用到
   terraform output -raw app_name
   terraform output -raw website_url
   ```

3. **建置與封裝 Web App**
   ```bash
   cd ../aspnet
   dotnet restore
   dotnet publish --configuration Release --output ./publish
   pushd publish
   zip -r ../deploy.zip .
   popd
   ```

4. **Zip Deploy 至 App Service**
   ```bash
   az login  # 若尚未使用 Azure CLI 登入
   az webapp deploy \
     --resource-group <resource_group> \
     --name <app_name> \
     --type zip \
     --src-path $(pwd)/deploy.zip
   ```

5. **驗證**：造訪 `terraform output -raw website_url`，確認可使用 Microsoft Entra 帳號登入並讀取 Graph 資料。

## GitHub Actions 自動部署
1. 在 repository 建立 `production` environment，並設定下列 secrets：

   | 名稱                    | 說明                                                                                    |
   | ----------------------- | --------------------------------------------------------------------------------------- |
   | `AZURE_CLIENT_ID`       | 對應 Service Principal / Federated Credential 的應用程式 (App Registration) client id。 |
   | `AZURE_TENANT_ID`       | Azure AD 租用戶 ID。                                                                    |
   | `AZURE_SUBSCRIPTION_ID` | 目標訂閱 ID。                                                                           |

   若需自訂部署參數，可在同一 environment 設定下列 variables：

   | 名稱             | 預設值   | 用途                 |
   | ---------------- | -------- | -------------------- |
   | `AZURE_LOCATION` | `eastus` | Terraform 部署位置。 |
   | `CODENAME`       | `webapp` | 用於資源命名。       |
   | `APPSERVICE_SKU` | `F1`     | App Service SKU。    |

2. 執行 `Deploy to Azure` workflow (`.github/workflows/deploy.yml`)：
   - **terraform-deploy** 工作會以 OIDC 登入 Azure，執行 `terraform init/plan/apply`，並輸出 `resource_group` 與 `app_name`。
   - **build-and-deploy** 工作會建置 ASP.NET 專案、產生 zip 套件，並以 `az webapp deploy --type zip` 發佈到 Terraform 建立的 App Service。
   - 兩個工作皆執行在 `production` environment，確保僅在核准後運作。

3. 若需清除資源，啟動 `Destroy Azure Infrastructure` workflow (`.github/workflows/destroy.yml`)，輸入 `destroy` 以確認後即可執行 `terraform destroy`。

## 本機開發與測試
```bash
cd src/aspnet
dotnet restore
dotnet run
# 瀏覽 https://localhost:5001
```

- 將 `AzureAd` 與 `ApplicationInsights` 相關設定寫入 `.env` 或 User Secrets，可避免修改 `appsettings.json`。
- 建議在本機啟用 [Azure CLI Managed Identity 模擬](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/how-to-configure-managed-identity-service-principal) 或使用測試憑證。

## 參考資料
- 原始範例：[ASP.NET Core 8.0 Web App - Sign-in user](https://github.com/Azure-Samples/ms-identity-docs-code-dotnet/tree/main/web-app-aspnet)
- 憑證與 Managed Identity 設定細節：`src/aspnet/MANAGED_IDENTITY.md`
- GitHub Actions OIDC 登入 Azure：[azure/login@v2 documentation](https://github.com/Azure/login)
