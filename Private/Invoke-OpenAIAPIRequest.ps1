using namespace System.Collections
using namespace System.Text
using namespace System.Net
using namespace System.Net.Http
using namespace System.Runtime.InteropServices

function Invoke-OpenAIAPIRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Method = 'Post',

        [Parameter(Mandatory = $true)]
        [System.Uri]$Uri,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [securestring]$Token,

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [bool]$Stream = $false
    )

    #region Assert selected model is discontinued
    if ($null -ne $Body -and $null -ne $Body.model) {
        Assert-UnsupportedModels -Model $Body.model
    }
    #endregion

    #region Server-Sent-Events
    if ($Stream) {
        Invoke-OpenAIAPIRequestSSE -Method $Method -Uri $Uri -ContentType $ContentType -Token $Token -Body $Body -TimeoutSec $TimeoutSec
    }
    #endregion

    #region PowerShell 6 and higher
    elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        # Construct parameter for Invoke-WebRequest
        $IwrParam = @{
            Method         = $Method
            Uri            = $Uri
            ContentType    = $ContentType
            TimeoutSec     = $TimeoutSec
            Authentication = 'Bearer'
            Token          = $Token
        }

        if ($null -ne $Body) {
            if ($ContentType -match 'multipart/form-data') {
                $IwrParam.Form = $Body
            }
            elseif ($ContentType -match 'application/json') {
                $IwrParam.Body = ([System.Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Compress)))
            }
            else {
                $IwrParam.Body = $Body
            }
        }

        #region Send API Request
        try {
            $Response = Microsoft.PowerShell.Utility\Invoke-WebRequest @IwrParam
        }
        catch [HttpRequestException] {
            $ErrorCode = $_.Exception.Response.StatusCode.value__
            $ErrorReason = $_.Exception.Response.ReasonPhrase
            $ErrorMessage = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Ignore).error.message
            if (-not $ErrorMessage) {
                $ErrorMessage = $_.Exception.Message
            }
            Write-Error ('OpenAI API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage)
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        #endregion

        # Output
        Write-Output $Response.Content
    }
    #endregion

    #region Windows PowerShell 5
    elseif ($PSVersionTable.PSVersion.Major -eq 5) {
        # decrypt securestring
        $bstr = [Marshal]::SecureStringToBSTR($Token)
        $PlainToken = [Marshal]::PtrToStringBSTR($bstr)
        $headers = @{Authorization = "Bearer $PlainToken" }

        # Construct parameter for Invoke-WebRequest
        $IwrParam = @{
            Method          = $Method
            Uri             = $Uri
            ContentType     = $ContentType
            TimeoutSec      = $TimeoutSec
            Headers         = $headers
            UseBasicParsing = $true
        }
        if ($null -ne $Body) {
            if ($ContentType -match 'multipart/form-data') {
                $Boundary = New-MultipartFormBoundary
                $IwrParam.Body = New-MultipartFormContent -FormData $Body -Boundary $Boundary
                $IwrParam.ContentType = ('multipart/form-data; boundary="{0}"' -f $Boundary)
            }
            elseif ($ContentType -match 'application/json') {
                $IwrParam.Body = ([System.Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Compress)))
            }
            else {
                $IwrParam.Body = $Body
            }
        }

        #region Send API Request
        try {
            $Response = Microsoft.PowerShell.Utility\Invoke-WebRequest @IwrParam
        }
        catch [WebException] {
            $ErrorCode = $_.Exception.Response.StatusCode.value__
            $ErrorReason = $_.Exception.Response.StatusCode.ToString()
            $ErrorMessage = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Ignore).error.message
            if (-not $ErrorMessage) {
                $ErrorMessage = $_.Exception.Message
            }
            Write-Error ('OpenAI API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage)
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            $bstr = $PlainToken = $headers = $null
        }
        #endregion

        # Fix content charset from ISO-8859-1 to UTF-8 (only JSON)
        if ($Response.Headers.'Content-Type' -match 'application/json') {
            $Content = [Encoding]::UTF8.GetString([Encoding]::GetEncoding('ISO-8859-1').GetBytes($Response.Content))
        }
        else {
            $Content = $Response.Content
        }

        # Output
        Write-Output $Content
    }
    #endregion

    # Others (error)
    else {
        Write-Error 'This version of the PowerShell is not supported.'
        return
    }
}
