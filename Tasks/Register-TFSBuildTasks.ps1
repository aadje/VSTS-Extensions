function Publish-BuildTask{
    param(
       [string]$TaskPath = $PWD,
       [Parameter(Mandatory=$true)]$TfsUrl,
       [PSCredential]$Credential = (Get-Credential),
       [switch]$Overwrite = $true
    )

    # Load task definition from the JSON file
    $taskDefinition = (Get-Content $taskPath\task.json) -join "`n" | ConvertFrom-Json
    $taskFolder = Get-Item $TaskPath

    # Zip the task content
    Write-Output "Zipping task content"
    $taskZip = ("{0}\..\{1}.zip" -f $taskFolder, $taskDefinition.id)
    if (Test-Path $taskZip) { Remove-Item $taskZip }

    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    [IO.Compression.ZipFile]::CreateFromDirectory($taskFolder, $taskZip)

    # Prepare to upload the task
    Write-Output "Uploading task content"
    $headers = @{ "Accept" = "application/json; api-version=2.0-preview"; "X-TFS-FedAuthRedirect" = "Suppress" }
    $taskZipItem = Get-Item $taskZip
    $headers.Add("Content-Range", "bytes 0-$($taskZipItem.Length - 1)/$($taskZipItem.Length)")
    $url = ("{0}/_apis/distributedtask/tasks/{1}" -f $TfsUrl, $taskDefinition.id)
    if ($Overwrite) {
       $url += "?overwrite=true"
    }

    # Actually upload it
    Invoke-RestMethod -Uri $url -Credential $Credential -Headers $headers -ContentType application/octet-stream -Method Put -InFile $taskZipItem
}

$ui = {
    
    https://github.com/Microsoft/vso-agent-tasks
    https://blogs.infosupport.com/custom-build-tasks-in-tfs-2015/
    https://marketplace.visualstudio.com/manage/publishers/...
    https://www.visualstudio.com/integrate/extensions/publish/overview
    https://msdn.microsoft.com/en-us/Library/vs/alm/Build/scripts/variables
    https://github.com/Microsoft/tfs-cli
    
    ## Using the Node TFS Cross Platform Command Line Interface (TFX-CLI)
    # Install using node
    npm install -g tfx-cli
    # Login using basic Auth, which should be enabled in de Virtual tfs site (does not werk in ps) 
    tfx login --authtype basic
    #collection url > http://..:8080/tfs/DefaultCollection
    #Enter username > MyUser

    tfx build tasks list
    # Upload
    tfx build tasks upload d:\Tasks\Wyam\ --overwrite
    # Scaffold new local task (does not work in ps) 
    tfx build tasks create 
    # Delete a task 
    tfx build tasks delete 89994534-b78a-41ab-8ea1-cf56732337ae


    ## Using the Rest api and the Publish-BuildTask cmdlet
    #https://pitt.visualstudio.com/_apis/distributedtask/tasks

    $credentials = Get-Credential
    Publish-BuildTask -Credential $credentials -TfsUrl http://...:8080/tfs
    Publish-BuildTask -Credential $credentials -TfsUrl https://pitt.visualstudio.com

}

