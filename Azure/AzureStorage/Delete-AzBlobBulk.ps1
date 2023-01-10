<#
    .DESCRIPTION
    The script aimed to bulk delete blobs that has "folder" structure.
    .PARAMETER StorageAccount
    Set storage account name context for the blob container

    .PARAMETER ResourceGroup
    Set the resourcegroup of the storage account

    .PARAMETER ContainerName
    Specify container name

    .PARAMETER BlobName
    Full blob name with prefix or prefix with asterisk

    .EXAMPLE
    Here we use blob prefix with asterisk to catch everythin uder that prefix
    .\Delete-AzBlobBulk.ps1 -ResourceGroup "RG-1" -StorageAccount "SA-1" -ContainerName "my-container" -BlobName "blob-prefix*"
#>

Param(
    # Parameter help description
    [Parameter(Mandatory=$true)]
    [String]$StorageAccount,
    [Parameter(Mandatory=$true)]
    [String]$ResourceGroup,
    [Parameter(Mandatory=$true)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true)]
    [String]$BlobName,
    [Parameter()]
    [Switch]$Reverse
)

# Set variables
$token     = $Null
$maxCount = 1000
$total     = 0

# Disable truncated srting to see whole value
$FormatEnumerationLimit=-1

# Connecting Azure Account if not conencted
$az_ctx = Get-AzContext -ErrorAction SilentlyContinue
if ($az_ctx){
    $az_ctx.Name
}
else {
    Connect-AzAccount
}

# Set context for accessing container
$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Context
# Set-AzCurrentStorageAccount -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccount

# When too many blobs its good to devide it to chunks
Get-AzStorageContainer -Context $ctx -Name $ContainerName | Get-AzStorageBlob -Blob $BlobName -MaxCount 10
$proceed = "Y"
Write-Host "`nHere are examples of the blods that going to be deleted"
Write-Host "!!! Please be aware that shown list of blobs just examples, it will delete everything with similar prefix" -ForegroundColor Red
$proceed = Read-Host "Do you want to proceed? (Y/n): "
if ($proceed -eq "Y" -or $proceed -eq "y"){
Do
{
    # Retrieve blobs using the MaxCount parameter
    $blobs = Get-AzStorageBlob -Container $ContainerName `
        -MaxCount $maxCount `
        -ContinuationToken $token `
        -Context $ctx `
        -Blob $BlobName
    
    # Removing blobs by bunch of 1000 blobs
    $blobs | Remove-AzStorageBlob
    
    # Loop through the bunch if needed more info, but more slower.
    # $blobCount = 1
    # Foreach ($blob in $blobs)
    # {
    # # Removing blob
    # Remove-AzStorageBlob -Container $ContainerName -Context $ctx -Blob $blob.Name -Force
    # write-output "Removed: " $blob.Name
    
    # #Display progress bar
    # $percent = $($blobCount/$maxCount*100)
    # Write-Progress -Activity "Processing blobs" -Status "$percent% Complete" -PercentComplete $percent
    # $blobCount++
    # }

    #Update $total
    $total += $blobs.Count
    
    # Exit if all blobs processed
    If($blobs.Length -le 0) { Break; }
    
    # Set continuation token to retrieve the next batch
    $token = $blobs[$blobs.Count -1].ContinuationToken
 }
 While ($null -ne $token)
 Write-Host "`n`nAccountName: $($ctx.StorageAccountName), ContainerName: $ContainerName" -ForegroundColor Green
 Write-Host "Removed $total blobs in $ContainerName." -ForegroundColor Green
}