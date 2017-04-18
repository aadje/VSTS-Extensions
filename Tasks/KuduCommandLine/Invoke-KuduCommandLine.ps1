[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [string][Parameter(Mandatory=$true)]$appserviceName,
    [string][Parameter(Mandatory=$true)]$username,
    [string][Parameter(Mandatory=$true)]$password,
    [string][Parameter(Mandatory=$true)]$command,
    [string][Parameter(Mandatory=$true)]$dir,
    [int][Parameter(Mandatory=$true)]$timeout
)

foreach($key in $PSBoundParameters.Keys)
{
    Write-Host ($key + ' = ' + $PSBoundParameters[$key])
}

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
$body = ConvertTo-Json (New-Object psobject @{ command = $command; dir = $dir})
Invoke-WebRequest -Method Post -Uri "https://$appserviceName.scm.azurewebsites.net/api/command" -Body $body -ContentType 'application/json' -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -TimeoutSec $timeout