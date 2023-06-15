# Used in custom detection rule during installation of Acrobat Reader from Win32 App profile. 
$versionNumber = "23.1.20174.0"

if ((Get-Item "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe").VersionInfo.FileVersion -eq $versionNumber) {
    Write-Host "Adobe Acrobat DC is nstalled"
    exit 0
}
elseif ((Get-Item "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe").VersionInfo.FileVersion -eq $versionNumber) {
    Write-Host "Adobe Acrobat DC is installed"
    exit 0
}   
else{
    Write-Host "Adobe reader is not installed"
    exit 1
}