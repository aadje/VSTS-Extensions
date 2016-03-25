[CmdletBinding(DefaultParameterSetName = 'None')]
param 
(
    [string] [Parameter(Mandatory=$false)]
    $inputDirectory = 'input',
    
    [string] [Parameter(Mandatory=$true)]
    $outputDirectory,
    
    [string] [Parameter(Mandatory=$false)] [ValidateSet('v0.11.1-beta','Latest','Local')]
    $wyamVersion = 'Latest',

    [string] [Parameter(Mandatory=$false)]
    $configPath = 'config.wyam',

    [string] [Parameter(Mandatory=$false)]
    $wyamPath
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

if(-not (Test-Path $outputDirectory))
{
    Write-Host creating $outputDirectory
    md $outputDirectory
}

# Get Wyam
$wyamExecPath 
if($wyamPath)
{
    if(-not (Test-Path $wyamPath))
    {
        throw "wyamPath path does not excist: $wyamPath"
    } 
    if(Test-Path $wyamPath -PathType Container )
    {
        $wyamExecPath = "$wyamPath\wyam.exe"
        if(-not (Test-Path $wyamExecPath))
        {
            throw "wyam.exe path does not excist: $wyamExecPath"
        } 
    }
    else
    {
        $wyamExecPath = $wyamPath
    }
} 
else 
{
    function Invoke-WyamDownload($version)
    {
        Add-Type -As System.IO.Compression.FileSystem

        $wc = New-Object System.Net.WebClient
        $zipInstall = "$pwd\Wyam.zip"
        $wc.DownloadFile("https://github.com/Wyamio/Wyam/releases/download/$version/Wyam-$version.zip", $zipInstall)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipInstall, "$pwd\Wyam")
        Remove-Item $zipInstall
        $wPath = "$pwd\Wyam\Wyam.exe"
        if(-not (Test-Path($wPath)))
        {
            throw "Wyam.exe version $version download to $wPath failed"
        } 
        else
        {
            Write-Host "Wyam $version downloaded to $wPath"
        }
        return $wPath
    }

    switch ($wyamVersion) 
    { 
        v0.11.1-beta 
        { 
            $wyamExecPath = Invoke-WyamDownload 'v0.11.1-beta' 
        }
        Latest 
        { 
            $wc = New-Object System.Net.WebClient
            $version = $wc.DownloadString("https://raw.githubusercontent.com/Wyamio/Wyam/master/RELEASE") -replace "`n|`r"
            Write-Host "Using latest wyam version on Github which is $version"  
            $wyamExecPath = Invoke-WyamDownload $version
        }
        Local 
        { 
            try
            {
                $wyamExecPath = (Get-Command Wyam.exe).Path
            }
            catch
            {
                throw 'Local Wyam.exe not found on Path'
            }
        } 
        default { throw "Wyam version $wyamVersion not supported" }
    }
}


# Run Wyam
& $wyamExecPath --input $inputDirectory --output $outputDirectory --config $configPath

# Clean up
del Wyam -Recurse -Force  -ErrorAction SilentlyContinue


