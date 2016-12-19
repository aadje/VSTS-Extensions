[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

$connectionType = Get-VstsInput -Name ConnectionType
$ftpEndpoint = Get-VstsInput -Name FtpEndpoint
$sshEndpoint = Get-VstsInput -Name SshEndpoint
$inputFilePath = Get-VstsInput -Name InputFilePath -Require
$remotePath = Get-VstsInput -Name RemotePath -Require
$testInputFilePath = Get-VstsInput -Name TestInputFilePath -Require -AsBool
 
$ftpMode = Get-VstsInput -Name FtpMode -Require
$ftpSecure = Get-VstsInput -Name FtpSecure -Require

Write-Host "ConnectionType: $connectionType"
Write-Host "FtpEndpoint id: $ftpEndpoint"
Write-Host "SsshEndpoint id: $sshEndpoint"
Write-Host "InputFilePath: $inputFilePath"
Write-Host "RemotePath: $remotePath"
Write-Host "TestInputFilePath: $testInputFilePath"

Write-Host "FtpMode: $ftpMode"
Write-Host "FtpSecure: $ftpSecure"

if($testInputFilePath -and (-not (Test-Path $inputFilePath))){
    throw "File InputFilePath $inputFilePath not found"
}

if(!(Test-Path .\WinSCP\WinSCPnet.dll)){
    throw "WinSCPnet.dll not found" 
}

Add-Type -Path  .\WinSCP\WinSCPnet.dll

if($connectionType -eq 'FTP'){
    $serviceEndpoint = Get-VstsEndpoint -Name $ftpEndpoint
    $serviceEndpointUri = New-Object System.Uri $serviceEndpoint.Url
} elseif ($connectionType -eq 'SSH'){
    $serviceEndpoint = Get-VstsEndpoint -Name $sshEndpoint
    $serviceEndpointUri = New-Object System.Uri $serviceEndpoint.Data.host
} else{
    throw "Connection not found"
}

$protocol = [WinSCP.Protocol]$serviceEndpointUri.Scheme
Write-Host "Protocol: $protocol" 

$hostName = $serviceEndpointUri.Host
Write-Host "host: $hostName" 

if($serviceEndpointUri.Port -eq -1){
    if($connectionType -eq 'FTP'){
        $port = 21
    } elseif ($connectionType -eq 'SSH'){
        $port = 22
    } else {
        throw "Connection not found"
    }
}else{
    $port = $serviceEndpointUri.Port
}
Write-Host "Ftp port: $port" 

$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = $protocol
    HostName = $hostName
    UserName = $serviceEndpoint.Auth.parameters.username
    Password = $serviceEndpoint.Auth.parameters.password
    PortNumber = $port
}

if($connectionType -eq 'FTP'){
    $sessionOptions.FtpMode = [WinSCP.FtpMode]$ftpMode
    $sessionOptions.FtpSecure = [WinSCP.FtpSecure]$ftpSecure 
} elseif ($connectionType -eq 'SSH'){
    $sessionOptions.SshHostKeyFingerprint = 'ssh-rsa 2048 99:0c:8a:46:18:11:d2:73:13:0e:0f:df:17:0d:00:cd'
} else {
    throw "Connection not found"
}

$session = New-Object WinSCP.Session

try
{
    $session.Open($sessionOptions)
 
    $transferOptions = New-Object WinSCP.TransferOptions
    $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
 
    $transferResult = $session.PutFiles($inputFilePath, $remotePath, $False, $transferOptions)
 
    # Throw on any error
    $transferResult.Check()
 
    foreach ($transfer in $transferResult.Transfers)
    {
        Write-Host ("Upload of {0} succeeded" -f $transfer.FileName)
    }
}
finally
{
    $session.Dispose()
}