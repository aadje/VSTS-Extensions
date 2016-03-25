[CmdletBinding(DefaultParameterSetName = 'None')]
param 
(
    [string] [Parameter(Mandatory=$false)]
    $inputDirectory = 'input',
    
    [string] [Parameter(Mandatory=$true)]
    $remoteUrl,
    
    [string] [Parameter(Mandatory=$false)]
    $remoteBranch = 'master',

    [string] [Parameter(Mandatory=$true)]
    $deploymentUser,
    
    [string][Parameter(Mandatory=$true)]
    $deploymentPassword
)

# Validate inputs
foreach($key in $PSBoundParameters.Keys)
{
    Write-Host ($key + ' = ' + $PSBoundParameters[$key])
}

if(-not (Test-Path $inputDirectory))
{
    throw "inputDirectory path does not excist: $inputDirectory"
}

if(!$deploymentPassword)
{
    throw "deploymentPassword not set"
}

try
{
    $gitPath = (Get-Command git.exe).Path
    Write-Host $gitPath
}
catch
{
    throw 'Local git.exe not found on Path'
}

$repoOutUri = New-Object UriBuilder $remoteUrl
$repoOutUri.UserName = $deploymentUser 
$repoOutUri.Password = $deploymentPassword
$repoOutUrl = $repoOutUri.ToString()

$repoOutPath = "$env:BUILD_STAGINGDIRECTORY\OutputRepo"

Write-Output "repoOutPath = $repoOutPath"

Write-Output "Cloning output: "
Push-Location $env:BUILD_STAGINGDIRECTORY
& $gitPath clone -b $remoteBranch $repoOutUrl 'OutputRepo' 2>&1 | Write-Host
$remoteBranch
Push-Location $repoOutPath
Write-Output "Remove old content in $PWD"
& $gitPath rm -rf $PWD
Pop-Location 

Write-Output "Copy input"
#Copy-Item -Path $inputDirectory -Destination $env:BUILD_STAGINGDIRECTORY -Exclude .\.git  -Force -Container -Recurse 
xcopy.exe $inputDirectory $repoOutPath /E
Push-Location $repoOutPath

Write-Output "Add new input to git"

& $gitPath config user.email "gittask@TFS"
& $gitPath config user.name "Git TFS task"
& $gitPath config push.default matching

Write-Output "Add new content on $PWD"
& $gitPath add -A 2>&1 | Write-Host
& $gitPath commit -a -m "Commit from TFS"

& $gitPath push 2>&1 | Write-Host
