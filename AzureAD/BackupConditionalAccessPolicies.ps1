<#
    .DESCRIPTION
    Backup conditional access policies as JSON files

    .PARAMETER Path
    Specify full path to bakup folder
#>


param(
    [Parameter(Mandatory)]
    [String] $Path
)

#######################################
####    Connect to MG Graph API    ####
#######################################
Connect-MgGraph -Scope "Policy.Read.All"
Select-MgProfile -Name "beta"
Write-Output "Successfully connected to MS Graph"

#######################################
####    Create folders structure   ####
#######################################
function createSubFolder {
    param ($folderName)
    
    if (-not (Test-Path "$Path\$folderName")) {
        $null = New-Item -Path "$Path\$folderName" -ItemType Directory -Force
        Write-Output "$folderName folder creaded"
        Write-Debug "$Path\$folderName"
    }
}

#######################################
####    Backup Names locations     ####
#######################################
try {
    $namedLocations = Get-MgIdentityConditionalAccessNamedLocation -All -Property Id, displayName
    $folderName = "Named Locations"
    createSubFolder($folderName)

    foreach ($namedLocation in $namedLocations) {
        $fileName = ($namedLocation.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        Get-MgIdentityConditionalAccessNamedLocation -NamedLocationId $namedLocation.Id -ErrorAction Stop | `
            ConvertTo-Json -Depth 100 | Out-File "$Path\$folderName\$fileName.json" 
        Write-Output "$fileName backup was created"
    }
}
catch {
    Write-Output "Named locations backup cannot be completed due to unexpected error"
    Write-Debug $_
}

#######################################
###          Backup policies       ####
#######################################
try {
    $policies = Get-MgIdentityConditionalAccessPolicy -All -Property Id, displayName
    $folderName = "Conditional Access Policies"
    createSubFolder($folderName)

    foreach ($policy in $policies) {
        $fileName = ($policy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -ErrorAction Stop | `
            ConvertTo-Json -Depth 100 | Out-File "$Path\$folderName\$fileName.json"
        Write-Output "$fileName backup was created"
    }
}
catch {
    Write-Output "Conditional Access Policies backup cannot be completed due to unexpected error"
    Write-Debug $_
}

Write-Output "Conditional Access Policies Backup completed"