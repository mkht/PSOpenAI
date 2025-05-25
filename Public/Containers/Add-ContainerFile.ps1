function Add-ContainerFile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Container')]
        [Alias('container_id')]
        [string][UrlEncodeTransformation()]$ContainerId,

        [Parameter(Mandatory, Position = 1)]
        [Alias('FileId')]
        [object[]]$File,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Container.Files' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $ContainerId

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        # Loop through each file to be added
        try {
            foreach ($_file in $File) {
                #region Construct parameters for API request
                $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

                if ($_file -is [System.IO.FileInfo]) {
                    $PostBody.file = $_file
                    $OpenAIParameter.ContentType = 'multipart/form-data'
                }
                elseif (Test-Path -LiteralPath $_file -PathType Leaf) {
                    $PostBody.file = Resolve-FileInfo $_file
                    $OpenAIParameter.ContentType = 'multipart/form-data'
                }
                else {
                    $PostBody.file_id = [string]$_file
                    $OpenAIParameter.ContentType = 'application/json'
                }
                #endregion

                #region Send API Request
                $params = @{
                    Method            = 'Post'
                    Uri               = $QueryUri
                    ContentType       = $OpenAIParameter.ContentType
                    TimeoutSec        = $OpenAIParameter.TimeoutSec
                    MaxRetryCount     = $OpenAIParameter.MaxRetryCount
                    ApiKey            = $OpenAIParameter.ApiKey
                    AuthType          = $OpenAIParameter.AuthType
                    Organization      = $OpenAIParameter.Organization
                    Body              = $PostBody
                    AdditionalQuery   = $AdditionalQuery
                    AdditionalHeaders = $AdditionalHeaders
                    AdditionalBody    = $AdditionalBody
                }
                $Response = Invoke-OpenAIAPIRequest @params

                # error check
                if ($null -eq $Response) {
                    return
                }
                #endregion

                #region Parse response object
                try {
                    $Response = $Response | ConvertFrom-Json -ErrorAction Stop
                }
                catch {
                    Write-Error -Exception $_.Exception
                }
                #endregion

                #region Output
                ParseContainerFileObject -InputObject $Response
                #endregion

                # Check cancellation
                $Cancellation.Token.ThrowIfCancellationRequested()
            }
        }
        catch [OperationCanceledException] {
            Write-TimeoutError
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            if ($null -ne $Cancellation) {
                $Cancellation.Dispose()
            }
        }
    }

    end {

    }
}
