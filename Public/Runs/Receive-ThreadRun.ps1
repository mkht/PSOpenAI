function Receive-ThreadRun {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_ThreadRun', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backward compatibility
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('run_id')]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

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
        [switch]$Wait,

        [Parameter()]
        [switch]$AutoRemoveThread,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        if ($AutoRemoveThread -and (-not $Wait)) {
            Write-Error -Exception ([System.InvalidOperationException]::new('The -AutoRemoveThread parameter cannot be used without the -Wait parameter.'))
        }

        $ThreadIds = [string[]]@()
        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        if ($PSCmdlet.ParameterSetName -ceq 'Get_Id') {
            $Run = PSOpenAI\Get-ThreadRun -ThreadId $ThreadId -RunId $RunId @CommonParams
        }

        if ($Wait -and $Run.status -ne 'completed') {
            $Run = $Run | PSOpenAI\Wait-ThreadRun @CommonParams
        }
        $ThreadIds += $Run.thread_id
        PSOpenAI\Get-Thread -ThreadId $Run.thread_id @CommonParams
    }

    end {
        if ($AutoRemoveThread) {
            if (-not $Wait) {
            }
            elseif ($ThreadIds.Count -gt 0) {
                $ThreadIds | PSOpenAI\Remove-Thread @CommonParams
            }
        }
    }
}
