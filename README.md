# Usefull PowerShell Scripts saved to reuse
\<Here will be some text\> <br />

---
**Install PowerShellGet module if you use PowerShell 5.** <br />
Windows PowerShell 5.1 comes with PowerShellGet version 1.0.0.1, which doesn't include the NuGet provider. The provider is required by PowerShellGet when working with the PowerShell Gallery.<br />
Use Install-PackageProvider to install NuGet before installing other modules<br />
Run the following command to install the NuGet provider:
```console
Install-PackageProvider -Name NuGet -Force
```
After you have installed the provider you should be able to use any of the PowerShellGet cmdlets with the PowerShell Gallery.
Just run this command to set PowerShellGallery as trusted source:
```console
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
```