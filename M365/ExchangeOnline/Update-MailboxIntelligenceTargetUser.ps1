<#
    .DESCRIPTION
    AntiPhishing Policies on Exchange Online Protection (EOP) allow only 350 user impersonation protection in one policy.
    The script checks actual list of active users and put them in a dedicated AntiPhishing Policy into the user impersonation protection list.
    
    For the users who inactive the script don't get rid of them from the AntiPishing Policy it just put them in the list of a separate policy.

    .PARAMETER PolicyNamePrefix

#>

# Parameters sections
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]$PolicyNamePrefix,
    [String]$TenantName
)

# Obtain access token
$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

# Create a new sesion if the session does not exist
# Connect-ExchangeOnline
Connect-ExchangeOnline -ManagedIdentity -Organization "cohovinyard.onmicrosoft.com"

# Get list existiong of policies
Get-AntiPhishPolicy


$tergetUserstoProtect = @()
$tergetUserstoProtect.Add("Daniyar Kassainov;daniyar.kassainov@watchfinder.co.uk")

New-AntiPhishPolicy -Name "Research Quarantine" `
    -AdminDisplayName "" `
    -EnableOrganizationDomainsProtection $true `
    -EnableTargetedDomainsProtection $true `
    -TargetedDomainsToProtect fabrikam.com `
    -TargetedDomainProtectionAction Quarantine `
    -EnableTargetedUserProtection $true `
    -TargetedUsersToProtect $tergetUserstoProtect `
    -TargetedUserProtectionAction Quarantine `
    -EnableMailboxIntelligenceProtection $true `
    -MailboxIntelligenceProtectionAction Quarantine `
    -EnableSimilarUsersSafetyTips $true `
    -EnableSimilarDomainsSafetyTips $true `
    -EnableUnusualCharactersSafetyTips $true