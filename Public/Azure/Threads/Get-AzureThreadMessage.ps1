function Get-AzureThreadMessage {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_Thread', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_Thread', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Thread')]$Thread,

        [Parameter(ParameterSetName = 'Get_ThreadId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_ThreadId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(ParameterSetName = 'Get_Thread', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get_ThreadId', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('message_id')]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$MessageId,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Alias('run_id')]
        [string]$RunId,

        [Parameter(ParameterSetName = 'List_Run', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'Get_RunStep', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.Thread.Run.Step')]$Step,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Parameter(ParameterSetName = 'List_Run')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Parameter(ParameterSetName = 'List_Run')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List_Thread', DontShow)]
        [Parameter(ParameterSetName = 'List_ThreadId', DontShow)]
        [Parameter(ParameterSetName = 'List_Run', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'List_Thread', DontShow)]
        [Parameter(ParameterSetName = 'List_ThreadId', DontShow)]
        [Parameter(ParameterSetName = 'List_Run', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Parameter(ParameterSetName = 'List_Run')]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('azure', 'azure_ad')]
        [string]$AuthType = 'azure',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Construct parameters
        $Parameters = $PSBoundParameters
        $Parameters.ApiType = [OpenAIApiType]::Azure
        $Parameters.AuthType = $AuthType

        # Invoke
        $steppablePipeline = {
            PSOpenAI\Get-ThreadMessage @Parameters
        }.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        $steppablePipeline.Process($PSItem)
    }

    end {
        $steppablePipeline.End()
    }
}
