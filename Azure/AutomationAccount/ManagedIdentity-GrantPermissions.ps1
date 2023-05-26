<#
    .DESCRIPTION
    Grant MS Graph API permission to the Managed Identity

    .PARAMETER PermissionName
    Specify required permission

    Use minimal required permission for your app.
    https://learn.microsoft.com/en-us/graph/permissions-reference

    .PARAMETER Identity
    Display name of your Managed identity

    .PARAMETER AppId
    Application ID to which you want to grant permission
    Default value (MS Graph): "00000003-0000-0000-c000-000000000000"

#>


param(
    [Parameter(Mandatory)]
    [String] $PermissionName,
    [Parameter(Mandatory)]
    [String] $Identity,
    [Parameter()]
    [String] $AppId = "00000003-0000-0000-c000-000000000000"
)

# Install the module
if (!(Get-InstalledModule -Name AzureAD -ErrorAction SilentlyContinue)){
    Install-Module AzureAD
}

# Login to Azure AD if not already logged in.
if (!(Get-AzureADTenantDetail -ErrorAction SilentlyContinue)){
    Connect-AzureAD
}

# Getting service principal object of Managed Identity
$MSI = (Get-AzureADServicePrincipal -Filter "displayName eq '$Identity'")
Start-Sleep -Seconds 10

# Getting service principal object of the applciation
$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$AppId'"

# Geting permissions
$AppRole = $GraphServicePrincipal.AppRoles | `
    Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"}

# Granting new permission
New-AzureAdServiceAppRoleAssignment -ObjectId $MSI.ObjectId -PrincipalId $MSI.ObjectId `
    -ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id