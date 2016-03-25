[CmdletBinding(DefaultParameterSetName = 'None')]
param 
(
    [string][Parameter(Mandatory=$true)]
    [string]$outFile
)

import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Azure"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Deployment.Chef"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.DevTestLabs"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.DTA"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.TestResults" 

Write-Host "Writing agent info to: $outFile"
 
"# TFS Build Angent" >> $outFile

"## Powershell version" >> $outFile
$PSVersionTable >> $outFile
"" >> $outFile  

"## Enviroment variables" >> $outFile  
dir env: | Format-Table -Expand Both -Wrap >> $outFile
"" >> $outFile  

"## Modules available" >> $outFile
Get-Module -ListAvailable | Format-Table -Expand Both -Wrap  >> $outFile 

"## Modules" >> $outFile  
Get-Module | Foreach { 
    "# Module $($_.Name)" >> $outFile  
    Get-Command -Module ($_.Name) | Get-Help >> $outFile
    "" >> $outFile  
}

