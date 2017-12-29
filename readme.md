# VsTs build and release tasks 

Powershell based build agent tasks which can be uploaded into a VsTs instance using the [tfx-cli](https://www.npmjs.com/package/tfx-cli)  

Note: most of these tasks have better alternatives in the VsTs [Marketplace](https://marketplace.visualstudio.com/vsts)

## Documentation

Please check [docs.microsoft.com/en-us/vsts/extend/develop/add-build-task](https://docs.microsoft.com/en-us/vsts/extend/develop/add-build-task)

## Tasks

### KuduZipDeploy

Upload zip files to Kudu using the [ZipDeploy api](https://github.com/projectkudu/kudu/wiki/Deploying-from-a-zip-file) 

### Wyam

Run the [wyam.io](https://wyam.io) static site generator in VsTs

### ExportEnvironmentVariables

Copy matching environment variables into a json file

### UpdateConfigTransform

Recursively run Microsoft [Xml Document Transformations](https://www.nuget.org/packages/Microsoft.Web.Xdt/) on config files in a directory matching a file pattern

### UpdateClientDependencyVersion

Update the version number in an Umbraco [ClientDependency.config](https://github.com/Shazwazza/ClientDependency) based on the current date

### WinSCP

Run SSH ftp commands using [WinSCP](https://winscp.net/eng/docs/library_powershell)

### KuduCommandLine

Run commandline commands on Kudu using the [command api](https://github.com/projectkudu/kudu/wiki/REST-API#command) 

### ExportAgentInfo 

Dump all environment variables and available Powershelll cmdlets in a textfile for debugging a Build agent


