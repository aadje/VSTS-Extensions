[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

$assemblaApiEndpoint = Get-VstsInput -Name AssemblaApiEndpoint -Require
$spaceId = Get-VstsInput -Name SpaceId -Require
$wikiPageId = Get-VstsInput -Name WikiPageId -Require
$outputFilePath = Get-VstsInput -Name OutputFilePath -Require

Write-Host "AssemblaApiEndpoint: $assemblaApiEndpoint"
Write-Host "SpaceId: $spaceId"
Write-Host "WikiPageId: $wikiPageId"
Write-Host "OutputFilePath: $outputFilePath"

$serviceEndpoint = Get-VstsEndpoint -Name $assemblaApiEndpoint -Require

Write-Host "serviceEndpoint.Url: $($serviceEndpoint.Url)" 

$key = $serviceEndpoint.Auth.parameters.username
$secret = $serviceEndpoint.Auth.parameters.password

$result = Invoke-WebRequest "https://api.assembla.com/v1/spaces/$spaceId/wiki_pages/$wikiPageId" -Headers @{'X-Api-key' = $key; 'X-Api-secret' = $secret}

Write-Host "Result StatusCode: $($result.StatusCode)"

$content = ConvertFrom-Json $result.Content

Write-Host "Outputting page: $($content.page_name)"

$content.contents > $outputFilePath

