[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$Task = Get-VstsInput -Name Task -Require
$ManageSlotFlag = Get-VstsInput -Name ManageSlotFlag -AsBool
$ResourceGroupName = Get-VstsInput -Name ResourceGroupName
$SlotName = Get-VstsInput -Name SlotName

Write-Host "ConnectedServiceName $ConnectedServiceName"
Write-Host "WebAppName $WebAppName"
Write-Host "Task $Task"
Write-Host "ManageSlotFlag $ManageSlotFlag"
Write-Host "ResourceGroupName $ResourceGroupName"
Write-Host "SlotName $SlotName"

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
$app = $apps | select -First 1

if($ManageSlotFlag)
{
    switch ($Task) 
    { 
        "Start"     { $app = $app | Start-AzureRmWebAppSlot -Slot Staging -ResourceGroupName $app.ResourceGroup } 
        "Stop"      { $app = $app | Stop-AzureRmWebAppSlot -Slot Staging -ResourceGroupName $app.ResourceGroup } 
        "Restart"   { $app = $app | Restart-AzureRmWebAppSlot -Slot Staging -ResourceGroupName $app.ResourceGroup }
        "Swap Slot" {
                        Write-Host "Start swapping $WebAppName to $SlotName..." 
                        $app | Swap-AzureRmWebAppSlot -SourceSlotName $SlotName 
                        Write-Host "Finished swapping $WebAppName to $SlotName"
                    }  
        default     { "Task $task not supported" }
    }
    Write-Host "$WebAppName State: $($app.State)"
}
else
{
    switch ($Task) 
    { 
        "Start"     { $app = $app | Start-AzureRmWebApp } 
        "Stop"      { $app = $app | Stop-AzureRmWebApp } 
        "Restart"   { $app = $app | Restart-AzureRmWebApp } 
        default     { "Task $task not supported" }
    }
    Write-Host "$WebAppName $SlotName State: $($app.State)"
}

