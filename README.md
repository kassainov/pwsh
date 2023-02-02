# pwsh_pub
Usefull PowerShell Scripts (Public)



# Install POwerShellGet module if you use PowerShell 5.

Windows PowerShell 5.1 comes with PowerShellGet version 1.0.0.1, which doesn't include the NuGet provider. The provider is required by PowerShellGet when working with the PowerShell Gallery.
Use Install-PackageProvider to install NuGet before installing other modules
Run the following command to install the NuGet provider:
<Install-PackageProvider -Name NuGet -Force>
After you have installed the provider you should be able to use any of the PowerShellGet cmdlets with the PowerShell Gallery.
Just run this command to set POwerShellGallery as trusted source:
<Set-PSRepository -Name PSGallery -InstallationPolicy Trusted>