<#
    .DESCRIPTION
    First draft of the script that 
    
    - Sets approvers, need to pass AzureAD user IDs as parameters
    - Enables MFA requirement, justification requirement
    - Sets activation duration to 4 hours

    Pass list of DisplayName roles to be changed via C:\Temp\Roles.txt

    Additional docs: 
    https://learn.microsoft.com/en-us/graph/api/resources/unifiedrolemanagementpolicy?view=graph-rest-1.0
    https://learn.microsoft.com/en-us/graph/how-to-pim-update-rules?tabs=http
#>

param (
    [Parameter()]
    [String] $ApproverId
)
Connect-MgGraph -Scope "RoleManagement.Read.All","RoleManagementPolicy.ReadWrite.Directory","RoleManagement.ReadWrite.Directory"
Select-MgProfile -Name "v1.0"
Start-Sleep -Seconds 3

# update Azure AD role settings
$RoleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition -Property Id,displayName
$DRassignments = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole'"
$RolesWithApprover = Get-Content -Path C:\Temp\Roles.txt

foreach ($Role in $RolesWithApprover) {
    $RoleDefinitionId = ($RoleDefinitions | Where-Object {$_.DisplayName -eq $Role}).Id

    #$RoleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451" # Test value to Global Reader
    $DirectoryRolePolciyId = ($DRassignments | Where-Object {$_.RoleDefinitionId -eq $RoleDefinitionId}).PolicyId
    
    if ($RoleDefinitionId -and $DirectoryRolePolciyId) {
        # Require approval to activate
        # Template for apporver setting
        $params = @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
            id = "Approval_EndUser_Assignment"
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
            setting = @{
                "@odata.type" = "microsoft.graph.approvalSettings"
                isApprovalRequired = $true
                isApprovalRequiredForExtension = $false
                isRequestorJustificationRequired = $true
                approvalMode = "SingleStage"
                approvalStages = @(
                    @{
                        "@odata.type" = "microsoft.graph.unifiedApprovalStage"
                        approvalStageTimeOutInDays = 1
                        isApproverJustificationRequired = $true
                        escalationTimeInMinutes = 0
                        primaryApprovers = @(
                            @{
                                "@odata.type" = "#microsoft.graph.singleUser"
                                userId = $ApproverId
                            }
                        )
                        isEscalationEnabled = $false
                        escalationApprovers = @(
                        )

                    }
                )
            }
        }

        $ruleId = "Approval_EndUser_Assignment"
        Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $DirectoryRolePolciyId -UnifiedRoleManagementPolicyRuleId $ruleId -BodyParameter $params

        # Set actvation duration to 4 hours
        # Parameters Template for duration setting
        $DurationParams = @{
            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
            id = "Expiration_EndUser_Assignment"
            isExpirationRequired = $true
            maximumDuration = "PT4H"
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