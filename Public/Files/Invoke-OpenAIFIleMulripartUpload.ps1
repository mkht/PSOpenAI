function Invoke-OpenAIFileMultiPartUpload {
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$File,

        [Parameter(Mandatory)]
        [int]$ChunkSize = 32MB,

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
        [securestring][SecureStringTransformation()]$ApiKey
    )

    begin {
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Uploads.Part.Add' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {

        $OpenAIParameter.Uri = ($OpenAIParameter.Uri.ToString() -f 'upload_123')

        $FileInfo = Resolve-FileInfo $File
        try {
            $ReadStream = [System.IO.File]::OpenRead($FileInfo.FullName)
            $SyncronizedReadStream = [System.IO.Stream]::Synchronized($ReadStream)

            [int]$JobSize = [Math]::Ceiling($FileInfo.Length / $ChunkSize)
            $JobList = [object[]]::new($JobSize)
            (0..($JobSize - 1)) | ForEach-Object {
                $JobList[$_] = @{
                    Id    = $_
                    Start = $_ * $ChunkSize
                    End   = [Math]::Min(($_ + 1) * $ChunkSize, $FileInfo.Length)
                }
            }

            $Jobs = $JobList | ForEach-Object {
                Start-ThreadJob -ScriptBlock {
                    param($ReadStream, $JobData, $OpenAIParameter, $ModulePath)
                    $ModulePath = Resolve-Path (Join-Path $ModulePath '..\..\Private')
                    Get-ChildItem $ModulePath -Filter *.ps1 | ForEach-Object { . $_.FullName }
                    $null = $ReadStream.Seek($JobData.Start, [System.IO.SeekOrigin]::Begin)
                    $Bytes = [byte[]]::new($JobData.End - $JobData.Start)
                    $null = $ReadStream.Read($Bytes, 0, $Bytes.Length)

                    $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
                    $PostBody.data = @{
                        Type    = 'bytes'
                        Content = $Bytes
                    }

                    $params = @{
                        Method        = $OpenAIParameter.Method
                        Uri           = $OpenAIParameter.Uri
                        ContentType   = $OpenAIParameter.ContentType
                        TimeoutSec    = $OpenAIParameter.TimeoutSec
                        MaxRetryCount = $OpenAIParameter.MaxRetryCount
                        ApiKey        = $OpenAIParameter.ApiKey
                        AuthType      = $OpenAIParameter.AuthType
                        Organization  = $OpenAIParameter.Organization
                        Body          = $PostBody
                    }
                    $Response = Invoke-OpenAIAPIRequest @params
                    $Bytes = $null

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

                    Write-Output ([pscustomobject]@{
                            Id       = $JobData.Id
                            Response = $Response
                        })
                } -ArgumentList $SyncronizedReadStream, $_, $OpenAIParameter, $PSScriptRoot -ThrottleLimit 8
            }

            $Jobs | Receive-Job -Wait | ForEach-Object {
                if ($null -ne $_.Id) {
                    $JobList[$_.Id].Result = $_.Response
                }
            }
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        finally {
            $ReadStream.Close()
        }

        $JobList
    }

    end {

    }
}