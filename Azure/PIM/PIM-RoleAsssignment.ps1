<#
	.DESCRIPTION
	Role assignment to admin groups (outlines)

    .PARAMETER Path
    Specify path to the CSV file with Role and Group columns.

    .PARAMETER Admins
    List of admin user UPN comma separated

    .EXAMPLE
    PIM-RoleAssignment.ps1 -Path C:\Temp\Role-Group.csv -Admins 'admin@contoso.onmicrosoft.com','admin2@contoso.onmicrosoft.com'

#>

param (
    [Parameter(Mandatory)]
    [String] $Path,
    [Parameter()]
    [String[]] $Admins = @('admin@contoso.onmicrosoft.com','admin2@contoso.onmicrosoft.com')
)

# Create a role assignable groups
Connect-MgGraph -Scopes "Group.ReadWrite.All"
$roles = Import-Csv -Path $Path # "Roles-Groups assignment"

foreach ($role in $roles) {
    New-MgGroup -DisplayName "$($role.Group)" `
        -Description "PIM: Azure AD $($role.Role) role eligible group" `
        -MailNickName "$($role.Group)" `
        -MailEnabled:$false -SecurityEnabled -IsAssignableToRole:$true    
}

# assign eligible groups
Connect-AzureAD

foreach ($role in $roles) {
    $principalId = (Get-MgGroup -Filter "displayName eq '$($role.Group)'").Id
    $roleDefinitionId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$($role.Role)'").Id
    $params = @{
        "PrincipalId" = $principalId
        "RoleDefinitionId" = $roleDefinitionId
        "Justification" = "initial assignment"
        "DirectoryScopeId" = "/"
        "Action" = "AdminAssign"
        "ScheduleInfo" = @{
          "StartDateTime" = Get-Date
          "Expiration" = @{
            "Type" = "noExpiration"
            }
          }
         }
    New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params

    # Add member to the group
    foreach ($admin in $admins) {
        if ($role.$($admin) -eq "Eligible"){
            $member = (Get-AzureADuser -SearchString $admin).ObjectId
            Add-AzureADGroupMember -ObjectId $principalId -RefObjectId $member
        }
    }
}