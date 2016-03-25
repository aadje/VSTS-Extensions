[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [string][Parameter(Mandatory=$true)]$rootDirectory,
    [string][Parameter(Mandatory=$true)]$environmentName,
    [string][Parameter(Mandatory=$true)]$microsoftWebXmlTransformAssemblyPath,
    [string][Parameter(Mandatory=$true)]$deleteTransformFiles
)

foreach($key in $PSBoundParameters.Keys)
{
    Write-Host ($key + ' = ' + $PSBoundParameters[$key])
}

if(-not (Test-Path($rootDirectory)))
{
    throw "Input rootDirectory path does not excist: $rootDirectory"
}

if(-not (Test-Path($microsoftWebXmlTransformAssemblyPath)))
{
    throw "Input microsoftWebXmlTransformAssemblyPath does not excist: $microsoftWebXmlTransformAssemblyPath"
}

Add-Type -Path $microsoftWebXmlTransformAssemblyPath

$paths = @()
$transFormConfigs
$environmentName = $environmentName.ToLower()
$deleteTransformFilesBool = [System.Convert]::ToBoolean($deleteTransformFiles)
$configs = dir -Recurse "$($rootDirectory)\*.$environmentName.config"

if(!$configs)
{
    Write-Warning "No $environmentName configs transformed in Directory $rootDirectory "
}

foreach($config in $configs){
    $configName = $config.FullName.ToLower().Replace(".$environmentName.", ".")
    $transFormConfigs = dir ([System.IO.Path]::GetDirectoryName($configName ) + "\" + [System.IO.Path]::GetFileNameWithoutExtension($configName) + ".*.config")

    $paths += @{
        TransformPath = $config.FullName
        Config = $configName
        TransFormConfigs = $transFormConfigs
    }
}

foreach($path in $paths){
    $doc = New-Object -TypeName Microsoft.Web.XmlTransform.XmlTransformableDocument
    $doc.Load($path.Config);
    $tranform  = New-Object -TypeName Microsoft.Web.XmlTransform.XmlTransformation -ArgumentList $path.TransformPath
    $tranform.Apply($doc) | Out-Null
    $doc.Save($path.Config)
    Write-Host "$($path.Config) transformed to $environmentName" -BackgroundColor DarkGreen
    if($deleteTransformFilesBool){
        Write-Verbose "Delete $($path.TransFormConfigs)" -Verbose
        $path.TransFormConfigs | Remove-Item    
    }
}
