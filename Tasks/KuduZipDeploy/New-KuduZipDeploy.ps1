[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$ManageSlotFlag = Get-VstsInput -Name ManageSlotFlag -AsBool
$ResourceGroupName = Get-VstsInput -Name ResourceGroupName
$SlotName = Get-VstsInput -Name SlotName
$InputFilePath = Get-VstsInput -Name InputFilePath

Write-Host "ConnectedServiceName $ConnectedServiceName"
Write-Host "WebAppName $WebAppName"
Write-Host "ManageSlotFlag $ManageSlotFlag"
Write-Host "ResourceGroupName $ResourceGroupName"
Write-Host "SlotName $SlotName"
Write-Host "InputFilePath $InputFilePath"

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
$app = $apps | select -First 1

if($ManageSlotFlag){
    $kuduApiUri = "https://$WebAppName`-$SlotName.scm.azurewebsites.net"
}
else{
    $kuduApiUri = "https://$WebAppName.scm.azurewebsites.net/api"
}

$resourceType = "Microsoft.Web/sites/config"
$resourceName = "$WebAppName/publishingcredentials"
$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $app.ResourceGroup -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force

$header = "{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword
$header = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($header))
$header = "Basic $header"
$headers = @{"Authorization"=$header;"If-Match"="*"}

write-host "start uploading to: $requestUri"
$requestUri = "https://$WebAppName.scm.azurewebsites.net/api/zipdeploy"  #?isAsync=true / $response.Headers.Location
    
$response = Invoke-WebRequest -Uri $requestUri -Headers $headers -Method Post -InFile $InputFilePath -ContentType "multipart/form-data"
Write-Host "Response:"
Write-Output $response
Write-Host "Deployment logs at: https://$WebAppName.scm.azurewebsites.net/api/deployments"
