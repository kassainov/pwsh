<#
    .DESCRIPTION
    Ensures that legacy on-prem WSUS settings deleted from device after migration to Azure AD only setup and to manageendpoint updates via Intune update rings polcicies.
#>

try {
    Remove-Item HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Recurse -ErrorAction Stop
    Write-Host "WSUS settings removed"
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "WSUS settings is not there"
}
catch {
    Write-Error "Error while removing registry value"
}