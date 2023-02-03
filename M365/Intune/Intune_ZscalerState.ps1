<#
    .DESCRIPTION
    Intune custom compliance check script used to evaluate Zscaler Client Connector's connection state.
    registry keys: https://help.zscaler.com/z-app/zscaler-app-registry-keys
#>

# Default values
$ZscalerState = @{"State" = "Default value"; "ZNW" =  $false; "ZPA" =  $false; "ZWS" = $false}

# Getting registry keys and comaping with desired state
try {
    $RegZSApp = Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\Software\Zscaler\App -ErrorAction Stop
    $ZNW = $RegZSApp.ZNW_State
    $ZPA = $RegZSApp.ZPA_State
    $ZWS = $RegZSApp.ZWS_State
    
    # Check States
    if ($ZNW -eq "" -or $ZPA -eq "" -or $ZWS -eq ""){
            $ZscalerState.State = "Registry key values are empty"
    }
    else {
        $ZNWGoodStates = @("TRUSTED_VPN", "TRUSTED")
        if ($ZNWGoodStates.Contains($ZNW)) {
            $ZscalerState = @{"State" = "Connected"; "ZNW" = $true; "ZPA" = $true; "ZWS" = $true}
        }
        else {
            $ZscalerState.State = "Not connected"
        }
    }
}
catch [System.Management.Automation.ItemNotFoundException] {
    $ZscalerState.State = "Not enrolled"
}
catch {
    $ZscalerState.State = "Error happened while reading registry value"
}
# Returning state
return $ZscalerState | ConvertTo-Json -Compress