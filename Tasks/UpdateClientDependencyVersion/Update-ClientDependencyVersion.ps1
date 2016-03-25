[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [string][Parameter(Mandatory=$true)]$rootDirectory
)

foreach($key in $PSBoundParameters.Keys)
{
    Write-Host ($key + ' = ' + $PSBoundParameters[$key])
}

if(-not (Test-Path($rootDirectory)))
{
    throw "Input rootDirectory path does not excist: $rootDirectory"
}

$configs = dir -Recurse -Path $rootDirectory -Name ClientDependency.config

if(!$configs)
{
    Write-Warning "No ClientDependency.config files foundin Directory $rootDirectory "
}

$version = [DateTime]::Now.ToString("yyMMddHHmm")

foreach($config in $configs){
    $path = "$rootDirectory\$config"
    $xml = [xml](get-content $path)
    $xml.get_DocumentElement().version = $version
    $xml.Save($path)

    Write-Host "$config Version updated to $version"
}