<#
    .DESCRIPTION
    Draft update notification settings for Azure AD roles
#>

# Connect to MS Graph
Connect-MgGraph -Scope "RoleManagement.Read.All","RoleManagementPolicy.ReadWrite.Directory","RoleManagement.ReadWrite.Directory"
Select-MgProfile -Name "v1.0"
Start-Sleep -Seconds 3

# Get reference identities and role to change
$RoleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition -Property Id,displayName
$RoleAssignments = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole'"
$RolesNotifications = Get-Content -Path C:\Temp\Roles.txt

foreach ($Role in $RolesNotifications) {
    $RoleDefinitionId = ($RoleDefinitions | Where-Object {$_.DisplayName -eq $Role}).Id

    #$RoleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451" # Test value to Global Reader
    $DirectoryRolePolciyId = ($RoleAssignments | Where-Object {$_.RoleDefinitionId -eq $RoleDefinitionId}).PolicyId
    
    if ($RoleDefinitionId -and $DirectoryRolePolciyId) {
        # 
        # Template for Notification settings
        $params = @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule"
            id = "Notification_Requestor_Admin_Eligibility"
            notificationType = "Email"
            recipientType = "Requestor"
            notificationLevel = "None"
            isDefaultRecipientsEnabled = $false
            notificationRecipients = @()
            target = @{
                caller = "EndUser"
                operations = @(
                    "all"
                )
                level= "Eligibility"
                inheritableSettings = @()
                enforcedSettings = @()
            }
        }

        $ruleId = "Notification_Requestor_Admin_Eligibility"
        Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $DirectoryRolePolciyId -UnifiedRoleManagementPolicyRuleId $ruleId -BodyParameter $params

        # Set actvation duration to 4 hours
        # Parameters Template for duration setting
        $DurationParams = @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
            id = "Expiration_EndUser_Assignment"
            isExpirationRequired = $true
            maximumDuration = "PT9H"
            target = @{
                caller = "EndUser"
                operations = @(
                    "All"
                )
                level = "Assignment"
                inheritableSettings = @(
                )
                enforcedSettings = @(
                )
            }
        }
        $ruleId = "Expiration_EndUser_Assignment"
        Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $DirectoryRolePolciyId -UnifiedRoleManagementPolicyRuleId $ruleId -BodyParameter $DurationParams


        # Enable MFA and justification requirement
        # Parameters Template for MFA and Justification setting
        $MFAparams = @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
            id = "Enablement_EndUser_Assignment"
            enabledRules = @(
                "Justification"
                "MultiFactorAuthentication"
            )
            target = @{
                "@odata.type" = "microsoft.graph.unifiedRoleManagementPolicyRuleTarget"
                caller = "EndUser"
                operations = @(
                    "All"
                )
                level = "Assignment"
                inheritableSettings = @(
                )
                enforcedSettings = @(
                )
            }
        }
        $ruleId = "Enablement_EndUser_Assignment"
        Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $DirectoryRolePolciyId -UnifiedRoleManagementPolicyRuleId $ruleId -BodyParameter $MFAparams
    }
}