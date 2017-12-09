# Deploy packages to Azure App Service using Kudu zipdeploy

Kudu is the engine behind the deployments in the Azure App Service and supports deploying  files using Ftp, Git, MSDeploy (Web Deploy) and plain zip packages.

This task uses the zipdeploy api in Kudu and can only deploy zip packages. The zipdeploy api is intended for easy deployments of ready-to-run sites and offers good results when deploying large amounts of small files.

The Kudu Github Wiki contains more information about zipdeploy  
[github.com/projectkudu/kudu/wiki/Deploying-from-a-zip-file](https://github.com/projectkudu/kudu/wiki/Deploying-from-a-zip-file)  
[github.com/projectkudu/kudu/wiki/REST-API#user-content-zip-deployment](https://github.com/projectkudu/kudu/wiki/REST-API#user-content-zip-deployment)

## Usage

Use a Connected ARM Service to select an App Service and optional deployment slot in your Azure subscription.
Add the path to the zip file you want to deploy. The zip file can be created using any previous task or script in your pipeline 