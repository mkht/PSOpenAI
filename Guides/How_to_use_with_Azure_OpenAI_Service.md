# How to use with Azure OpenAI Service

PSOpenAI supports for Azure OpenAI Service.

## Setup

For the following sections to work properly we first have to setup some things.

### Create resource

If you don't create an Azure OpenAI resource yet, you need to create it by following steps.  

1. Go to https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI
1. Fill out all mandatory parameters. then create resource.
1. Go to resource page that has been created.

### Get keys and endpoint name.

You have to get the access token and endpoint name to call the API.

1. Go to resource page that has been created.
1. Click on [Keys and Endpoint]
1. Find your API key and Endpoint name.
1. Set these to the variables for using by script.

Note: Two keys are provided as standard for rotation, but only one of them is needed.

![image](./images/azure_keys_and_endpoint_01.png)


### Set API key and Endpoint as environment variables.

```powershell
Import-Module ..\PSOpenAI.psd1

$AuthType = 'azure'
$env:OPENAI_API_KEY = '<Put your api key here>'
$env:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
```

### (Optional) Use Entra ID Authentication

You can get a user-based token from Entra ID by logging in with the [Az.Accounts](https://www.powershellgallery.com/packages/Az.Accounts/) PowerShell module or Azure CLI tools. This way you are secured by MFA and no need for a API Key.

Users logging in with Entra ID must be assigned a `Cognitive Services User` role or higher privileges.

Roles can be assigned from the [Access Control (IAM)] in the resource page.

![image](./images/azure_iam_01.png)

```powershell
# To run the following code, you need to install Az.Accounts PowerShell module.
# Install-Module Az.Accounts
Import-Module Az.Accounts

# Login with Entra ID
Connect-AzAccount

# Retrive access token
$MyToken = Get-AzAccessToken -ResourceUrl 'https://cognitiveservices.azure.com'

# Set to variables
$AuthType = 'azure_ad'  # You need to set AuthType as "azure_ad".
$env:OPENAI_API_KEY = $MyToken.Token
$env:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
```

### Create model deployments manually

In Azure, the AI model to be used must be deployed under an arbitrary name.

1. Go to [Azure OpenAI Studio](https://oai.azure.com/) page.
1. Click on the [Deployments]
1. Click [Create new deployment], give it a name, select a model and version, then click [Create].

![image](./images/azure_model_deployments_01.png)

```powershell
$DeploymentName = '<Put your deployment name here>'
```

## Create chat completion

Now let's send a sample chat completion to the deployment.

```powershell
# Need to set these variables properly in the above codes.
# $AuthType
# $DeploymentName
# $env:OPENAI_API_KEY
# $env:OPENAI_API_BASE

Request-ChatCompletion `
  -ApiType Azure `  # This parameter switches to the Azure API.
  -Message 'Hello Azure OpenAI Service.' `
  -Model $DeploymentName `
  -AuthType $AuthType
```
