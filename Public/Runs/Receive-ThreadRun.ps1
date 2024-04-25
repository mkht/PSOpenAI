function Receive-ThreadRun {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({ ([string]$_.id).StartsWith('run_', [StringComparison]::Ordinal) -and ([string]$_.thread_id).StartsWith('thread_', [StringComparison]::Ordinal) })]
        [Alias('Run')]
        [Object]$InputObject,

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
        if ($Wait -and $InputObject.status -ne 'completed') {
            $InputObject = $InputObject | PSOpenAI\Wait-ThreadRun @CommonParams
        }
        $ThreadIds += $InputObject.thread_id
        PSOpenAI\Get-Thread -InputObject $InputObject.thread_id @CommonParams
        return
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
