<#
    .DESCRIPTION
    Automated script to backup Intune policies and apps

    .PARAMETER StorageAccountName
    Name of storage account where to store backups
    Default value: "wfintunebackup"

    .PARAMETER RGName
    Storage account Resource group
    Default value: "wf-rg-it-automationaccount"

    .PARAMETER ContainerName
    Blob container name
    Default value: "backup"
#>


param (
    [Parameter()]
    [string] $StorageAccountName = "SA name",
    [Parameter()]
    [string] $ContainerName = "backup",
    [Parameter()]
    [string] $ClientId = "app id",
    [Parameter()]
    [string] $TenantId = "tenant_id",
    [Parameter()]
    [string] $apiVersion = "Beta"
)

#Importing Modules
$Module_Name = "IntuneBackupAndRestore"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

$Module_Name = "Microsoft.Graph.Intune"
Write-Output "Importing Module $Module_Name"
Import-Module $Module_Name

#################################################
################## Login to MS Graph ########################
#################################################
$authority = "https://login.windows.net/$TenantId"
$ClientSecret = Get-AutomationVariable -Name intune_secret

Update-MSGraphEnvironment -AppId $ClientId -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
Connect-MSGraph -ClientSecret $ClientSecret -Quiet

### Creating Folders
if (!(Test-Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -Force -ItemType Directory
} else {
    Write-Output "Path C:\Temp already exists"
}

$Path = "C:\Temp\IntuneBackup"
if (!(Test-Path $Path)) {
    New-Item -Path $Path -Force -ItemType Directory
} else {
    Write-Output "Path $Path already exists"
}

#################################################
######## Starting Intune Backup #################
#################################################
$BackupTasks = @("Invoke-IntuneBackupClientApp";
"Invoke-IntuneBackupClientAppAssignment";
"Invoke-IntuneBackupConfigurationPolicy";
"Invoke-IntuneBackupConfigurationPolicyAssignment";
"Invoke-IntuneBackupDeviceCompliancePolicy";
"Invoke-IntuneBackupDeviceCompliancePolicyAssignment";
"Invoke-IntuneBackupDeviceConfiguration";
"Invoke-IntuneBackupDeviceConfigurationAssignment";
"Invoke-IntuneBackupDeviceManagementScript";
"Invoke-IntuneBackupDeviceManagementScriptAssignment";
"Invoke-IntuneBackupGroupPolicyConfiguration";
"Invoke-IntuneBackupGroupPolicyConfigurationAssignment";
"Invoke-IntuneBackupDeviceManagementIntent";
"Invoke-IntuneBackupAppProtectionPolicy";
"Invoke-IntuneBackupDeviceHealthScript";
"Invoke-IntuneBackupDeviceHealthScriptAssignment")

Write-Output "Starting Intune Backup"
try {
    #Start-IntuneBackup -Path $Path -ErrorAction Stop > $null
    foreach ($task in $BackupTasks){
        Invoke-Expression $task -Path $Path
        Start-Sleep(60)
    }
}
catch [System.Management.Automation.CommandNotFoundException] {
    Write-Output "Start-IntuneBackup is not recognized as the name of a cmdlet error occured"
}
catch {
    Write-Output "Cannot proceed backup"
    Write-Output $_
}

#################################################
######### Logon to Microsoft Azure ##############
#################################################

Connect-AzAccount -Identity

#################################################
######### Upload to Storage Account #############
#################################################

Write-Output "Uploading Intune Backup to storageaccount $($StorageAccountName) in container $($ContainerName)"

try {
    $FolderName = Get-Date -Format "yyyy-MM-dd"
    $sourceFileRootDirectory = $Path

    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName
    $container = Get-AzStorageContainer -Name $ContainerName -Context $ctx -ErrorAction Stop
    $container.CloudBlobContainer.Uri.AbsoluteUri
}
catch {
    Write-Output "Could not connect to storage account"
}
if ($container) {
    $filesToUpload = Get-ChildItem $sourceFileRootDirectory -Recurse -File

    foreach ($x in $filesToUpload) {
        $PartPath = ($x.fullname.Substring($sourceFileRootDirectory.Length)).Replace("\", "/")
        $FullPath = $FolderName + "/" + $PartPath
        Write-Verbose "Uploading $("\" + $x.fullname.Substring($sourceFileRootDirectory.Length + 1)) to $($container.CloudBlobContainer.Uri.AbsoluteUri + "/" + $FullPath)"
        Set-AzStorageBlobContent -File $x.fullname -Container $container.Name -Blob $FullPath -Context $ctx -Force:$true| Out-Null
    }
    Write-Output "Uploading of the backups completed."
}

### Clean Up Folder
if (Test-Path $Path) {
    Write-Output "Deleting $Path"
    Remove-Item $Path -Recurse -Force
} else {
    Write-Output "Path $Path does not exist"
}