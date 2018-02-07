[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$ManageSlotFlag = Get-VstsInput -Name ManageSlotFlag -AsBool
$ResourceGroupName = Get-VstsInput -Name ResourceGroupName
$SlotName = Get-VstsInput -Name SlotName
$Command = Get-VstsInput -Name Command
$Dir = Get-VstsInput -Name Dir
$Timeout = Get-VstsInput -Name Timeout -AsInt

Write-Host "ConnectedServiceName $ConnectedServiceName"
Write-Host "WebAppName $WebAppName"
Write-Host "ManageSlotFlag $ManageSlotFlag"
Write-Host "ResourceGroupName $ResourceGroupName"
Write-Host "SlotName $SlotName"
Write-Host "Command $Command"
Write-Host "Dir $Dir"
Write-Host "Timeout $Timeout"

if($ManageSlotFlag -and -not $SlotName){
    throw "$SlotName parameter needed for $Task"
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
    $requestUri = "https://$WebAppName`-$SlotName.scm.azurewebsites.net/api/command/"
    $resourceType = "Microsoft.Web/sites/slots/config"
    $resourceName = "$WebAppName/$SlotName/publishingcredentials"
} else{
    $requestUri = "https://$WebAppName.scm.azurewebsites.net/api/command/"
    $resourceType = "Microsoft.Web/sites/config"
    $resourceName = "$WebAppName/publishingcredentials"
}

$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $app.ResourceGroup -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force

$header = "{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword
$header = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($header))
$header = "Basic $header"
$headers = @{"Authorization"=$header;"If-Match"="*"}

$body = ConvertTo-Json (New-Object psobject @{ command = $Command; dir = $Dir})

Write-Host "Invoke: '$Command' on '$requestUri/$Dir'"

$response = Invoke-WebRequest `
    -Uri $requestUri `
    -Headers $headers `
    -Method Post `
    -Body $body `
    -ContentType 'application/json' `
    -ErrorAction SilentlyContinue `
    -TimeoutSec $Timeout `
    -UseBasicParsing

Write-Host "Response: $($response.StatusCode) $($response.StatusDescription)"
$response.Content | ConvertFrom-Json | Format-List



