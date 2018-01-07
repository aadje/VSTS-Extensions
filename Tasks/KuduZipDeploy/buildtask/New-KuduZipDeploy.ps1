[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$ManageSlotFlag = Get-VstsInput -Name ManageSlotFlag -AsBool
$ResourceGroupName = Get-VstsInput -Name ResourceGroupName
$SlotName = Get-VstsInput -Name SlotName
$InputFilePath = Get-VstsInput -Name InputFilePath
$ZipApi = Get-VstsInput -Name ZipApi
$IsAsync = Get-VstsInput -Name IsAsync -AsBool
$OutputFolderPath = Get-VstsInput -Name OutputFolderPath

Write-Host "ConnectedServiceName $ConnectedServiceName"
Write-Host "WebAppName $WebAppName"
Write-Host "ManageSlotFlag $ManageSlotFlag"
Write-Host "ResourceGroupName $ResourceGroupName"
Write-Host "SlotName $SlotName"
Write-Host "InputFilePath $InputFilePath"
Write-Host "ZipApi $ZipApi"
Write-Host "IsAsync $IsAsync"
Write-Host "OutputFolderPath $OutputFolderPath"

if($ManageSlotFlag -and -not $SlotName){
    throw "$SlotName parameter needed for $Task"
}

if(-not (Test-Path $InputFilePath)){ 
    throw "Zipfile at $InputFilePath does not exist" 
}

$vstsEndpoint = Get-VstsEndpoint -Name $ConnectedServiceName -Require
if($vstsEndpoint.Auth.Scheme -ne 'ServicePrincipal') {
    throw "$($vstsEndpoint.Auth.Scheme) endpoint not supported"
}

$cred = New-Object System.Management.Automation.PSCredential(
    $vstsEndpoint.Auth.Parameters.ServicePrincipalId,
    (ConvertTo-SecureString $vstsEndpoint.Auth.Parameters.ServicePrincipalKey -AsPlainText -Force))
Login-AzureRmAccount -Credential $cred -ServicePrincipal -TenantId $vstsEndpoint.Auth.Parameters.TenantId -SubscriptionId $vstsEndpoint.Data.SubscriptionId

$apps = Get-AzureRmWebApp -Name $WebAppName
if($apps.Count -ne 1){
    throw "$WebAppName not found"
}
$app = $apps | Select-Object -First 1

if($ManageSlotFlag){
    $requestUri = "https://$WebAppName`-$SlotName.scm.azurewebsites.net/api/"
    $resourceType = "Microsoft.Web/sites/slots/config"
    $resourceName = "$WebAppName/$SlotName/publishingcredentials"
} else{
    $requestUri = "https://$WebAppName.scm.azurewebsites.net/api/zipdeploy"
    $resourceType = "Microsoft.Web/sites/config"
    $resourceName = "$WebAppName/publishingcredentials"
}

$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $app.ResourceGroup -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force

$header = "{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword
$header = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($header))
$header = "Basic $header"
$headers = @{"Authorization"=$header;"If-Match"="*"}

if($ZipApi -eq 'ZipDeploy'){
    $requestUri = $requestUri + "zipdeploy"
    if($IsAsync){
        $requestUri = $requestUri + "?isAsync=true"
    }
    
    write-host "Uploading to $requestUri ..."
    Write-Host "Deployment logs at https://$WebAppName.scm.azurewebsites.net/api/deployments"
    
    $response = Invoke-WebRequest `
        -Uri $requestUri `
        -Headers $headers `
        -Method Post `
        -InFile $InputFilePath `
        -ContentType "multipart/form-data" `
        -ErrorAction SilentlyContinue `
        -UseBasicParsing

} elseif (Zip -eq 'Zip') {
    $requestUri = $requestUri + "zip/"
    if($OutputFolderPath){
        $requestUri = $requestUri + $OutputFolderPath
    }

    Write-Host "Uploading zip to $requestUri"

    $response = Invoke-WebRequest `
        -Uri $requestUri `
        -Headers $headers `
        -Method Put `
        -InFile $InputFilePath `
        -ContentType "multipart/form-data" `
        -ErrorAction SilentlyContinue `
        -UseBasicParsing
}

Write-Host "Response: $($response.StatusCode) $($response.StatusDescription) `n$($response.Content)"

if($response.StatusCode -eq 202) {
    Write-Host "Deployment is running at location $($response.Headers.Location)"
}