// <ms_docref_import_types>
using System.Collections;
using System.Text;
using System.Text.Json;
using dotenv.net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;
// </ms_docref_import_types>

// <ms_docref_add_msal>
WebApplicationBuilder builder = WebApplication.CreateBuilder(args);
IEnumerable<string>? initialScopes = builder.Configuration.GetSection("DownstreamApis:MicrosoftGraph:Scopes").Get<IEnumerable<string>>();

// Add Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    // Connection string will be automatically detected from:
    // 1. APPLICATIONINSIGHTS_CONNECTION_STRING environment variable (Azure)
    // 2. appsettings.json ApplicationInsights:ConnectionString
    options.ConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]
        ?? builder.Configuration["ApplicationInsights:ConnectionString"];
});

DotEnv.Load();
builder.Configuration.AddEnvironmentVariables();

builder.Services.AddMicrosoftIdentityWebAppAuthentication(builder.Configuration, "AzureAd")
    .EnableTokenAcquisitionToCallDownstreamApi(initialScopes)
        .AddInMemoryTokenCaches();
builder.Services.AddDownstreamApis(builder.Configuration.GetSection("DownstreamApis"));

builder.Services.AddTransient<IConfiguration>(x => builder.Configuration);

builder.Services.AddLogging();

// </ms_docref_add_msal>

// <ms_docref_add_default_controller_for_sign-in-out>
builder.Services.AddRazorPages().AddMvcOptions(options =>
    {
        var policy = new AuthorizationPolicyBuilder()
                      .RequireAuthenticatedUser()
                      .Build();
        options.Filters.Add(new AuthorizeFilter(policy));
    }).AddMicrosoftIdentityUI();
// </ms_docref_add_default_controller_for_sign-in-out>

// <ms_docref_enable_authz_capabilities>
WebApplication app = builder.Build();

var knownVars = (Hashtable)Environment.GetEnvironmentVariables();
var envDebug = new StringBuilder();
knownVars
    .Keys.Cast<string>()
    .OrderBy(x => x)
    .ToList()
    .ForEach(x => envDebug.Append(x).Append(" = ").AppendLine(knownVars[x]?.ToString() ?? string.Empty));

var logger = app.Services.GetRequiredService<ILogger<Program>>();
logger.LogInformation(envDebug.ToString());

app.UseAuthentication();
app.UseAuthorization();
// </ms_docref_enable_authz_capabilities>

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.MapRazorPages();
app.MapControllers();

app.Run();
