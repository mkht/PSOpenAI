function Add-AgentEnvironmentFile {
    [CmdletBinding(DefaultParameterSetName = 'FileId')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id', 'environment_id')]
        [string][UrlEncodeTransformation()]$EnvironmentId,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'FileId', ValueFromPipelineByPropertyName)]
        [Alias('file_id')]
        [string]$FileId,

        [Parameter(Mandatory, Position = 2, ParameterSetName = 'FileId')]
        [ValidatePattern('^/workspace(?:/|$)')]
        [string]$Path,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'Body')]
        [System.Collections.IDictionary]$Body,

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

    process {
        $PostBody = if ($PSCmdlet.ParameterSetName -eq 'Body') {
            $Body
        }
        else {
            [ordered]@{
                type    = 'file_id'
                file_id = $FileId
                path    = $Path
            }
        }

        Invoke-AgentApiRequest -EndpointName 'Agent.Environments' -Path "$EnvironmentId/files" -Method Post -Parameters $PSBoundParameters -Body $PostBody -TypeName 'PSOpenAI.Agent.EnvironmentFile'
    }
}
