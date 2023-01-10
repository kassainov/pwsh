<#
    .DESCRIPTION
    The script aimed to bulk delete blobs that has "folder" structure.
    .PARAMETER StorageAccount
    Set storage account name context for the blob container

    .PARAMETER ResourceGroup
    Set the resourcegroup

    .EXAMPLE
    Delete-AzBlobBulk
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
$az_ctx = Get-AzContext
if (Get-AzContext){
    $az_ctx.Name
}
else {
    Connect-AzAccount
}

# Set context for accessing container
$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Context
#Set-AzCurrentStorageAccount -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccount

# When too many blobs its good to devide it to chunks
Get-AzStorageContainer -MaxCount 5 -Context $ctx | Get-AzStorageBlob -Blob $BlobName 
$proceed = "Y"
$proceed = Read-Host "Do you want to proceed? (Y/n): "
if ($proceed -eq "Y" -or $proceed -eq "y"){
Do
{
     #Retrieve blobs using the MaxCount parameter
     $blobs = Get-AzStorageBlob -Container $ContainerName `
         -MaxCount $maxCount `
         -ContinuationToken $token `
         -Context $ctx
     $blobCount = 1
     
     #Loop through the batch
     Foreach ($blob in $blobs)
     {
        # Removing blob
        #Remove-AzStorageBlob -Blob $blob -Context $ctx -Force
        Write-Output "Here I could remove blob " + $blob.Name
        #Display progress bar
        $percent = $($blobCount/$maxCount*100)
        Write-Progress -Activity "Processing blobs" -Status "$percent% Complete" -PercentComplete $percent
        $blobCount++
     }

     #Update $total
     $total += $blobs.Count
      
     #Exit if all blobs processed
     If($blobs.Length -le 0) { Break; }
      
     #Set continuation token to retrieve the next batch
     $token = $blobs[$blobs.Count -1].ContinuationToken
 }
 While ($null -ne $token)
 Write-Host "`n`n   AccountName: $($ctx.StorageAccountName), ContainerName: $ContainerName `n"
 Write-Host "Processed $total blobs in $ContainerName."
}