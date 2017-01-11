[CmdletBinding(DefaultParameterSetName = 'None')]
param 
(
    [string][Parameter(Mandatory=$true)]$variables,
    [string][Parameter(Mandatory=$true)]$outFiles,
    [string][Parameter(Mandatory=$true)]$addCreateDate
)

function Test-Any {
    [CmdletBinding()]
    param($EvaluateCondition,
        [Parameter(ValueFromPipeline = $true)] $ObjectToTest)
    begin {
        $any = $false
    }
    process {
        if (-not $any -and (& $EvaluateCondition $ObjectToTest)) {
            $any = $true
        }
    }
    end {
        $any
    }
}

$result = [ordered]@{}
$params = $variables.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
$files = $outFiles.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
$addCreateDateBool = [System.Convert]::ToBoolean($addCreateDate)

Write-Host "variables  : $params"
Write-Host "out files  : $files"

dir env: | where { 
    $envParam = $_.Name.ToLower()
    $params | Test-Any { 
        select-string -Pattern $_.ToLower() -InputObject $envParam 
    }
} | Sort Key | foreach { 
    $result.Add($_.Key, $_.Value)
    Write-Host "$($_.Key) : $($_.Value)"
}

if($addCreateDateBool){
    $result.Add('CREATE_DATE', "$([dateTime]::now.Tostring('o'))")
}

$files | foreach {
    $result | convertTo-Json > $_
}