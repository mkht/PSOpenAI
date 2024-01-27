class APIRequestException : System.Net.Http.HttpRequestException {
    Hidden [Nullable[System.Net.HttpStatusCode]]$_StatusCode
    Hidden [object]$_Response
    Hidden [string]$_Type
    Hidden [string]$_Code
    Hidden [string]$_Param
    Hidden [object]$_Content

    APIRequestException(
        [string]$message,
        [object]$response,
        [object]$content,
        [Nullable[System.Net.HttpStatusCode]]$statusCode,
        [Exception]$innerException
    ) : base(
        [string]$message,
        [Exception]$innerException
    ) {
        $this.AddPublicMember()
        $this._StatusCode = $statusCode
        $this._Content = $content

        if ($response -is [System.Net.Http.HttpResponseMessage]) {
            $this._Response = $response
        }
        elseif ($response -is [System.Net.WebResponse]) {
            $this._Response = $response
        }

        if ($content.error.type -is [string]) {
            $this._Type = $content.error.type
        }
        if ($content.error.code -is [string] -or $content.error.code -is [int]) {
            $this._Code = $content.error.code -as [string]
        }
        if ($content.error.param -is [string]) {
            $this._Param = $content.error.param
        }
    }

    Hidden AddPublicMember() {
        $Members = $this | Get-Member -Force -MemberType Property -Name '_*'
        foreach ($Member in $Members) {
            $PublicPropertyName = $Member.Name -replace '_', ''
            # Define getter
            $Getter = "return `$this.{0}" -f $Member.Name
            $Getter = [ScriptBlock]::Create($Getter)
            # Define setter
            $Setter = "Write-Warning `"'{0}' is a ReadOnly property.`"" -f $PublicPropertyName
            $Setter = [ScriptBlock]::Create($Setter)
            $AddMemberParams = @{
                Name        = $PublicPropertyName
                MemberType  = 'ScriptProperty'
                Value       = $Getter
                SecondValue = $Setter
                Force       = $true
            }
            $this | Add-Member @AddMemberParams
        }
    }
}

class BadRequestException : APIRequestException {
    BadRequestException (
        [string]$message,
        [object]$response,
        [object]$content,
        [Exception]$innerException
    ) : base(
        [string]$message,
        [object]$response,
        [object]$content,
        [System.Net.HttpStatusCode]400,
        [Exception]$innerException
    ) {}
}


class ContentFilteredException : APIRequestException {
    ContentFilteredException (
        [string]$message,
        [object]$response,
        [object]$content,
        [Exception]$innerException
    ) : base(
        [string]$message,
        [object]$response,
        [object]$content,
        [System.Net.HttpStatusCode]400,
        [Exception]$innerException
    ) {}
}

class UnauthorizedException : APIRequestException {
    UnauthorizedException (
        [string]$message,
        [object]$response,
        [object]$content,
        [Exception]$innerException
    ) : base(
        [string]$message,
        [object]$response,
        [object]$content,
        [System.Net.HttpStatusCode]401,
        [Exception]$innerException
    ) {}
}

class NotFoundException : APIRequestException {
    NotFoundException (
        [string]$message,
        [object]$response,
        [object]$content,
        [Exception]$innerException
    ) : base(
        [string]$message,
        [object]$response,
        [object]$content,
        [System.Net.HttpStatusCode]404,
        [Exception]$innerException
    ) {}
}

class RateLimitExceededException : APIRequestException {
    RateLimitExceededException (
        [string]$message,
        [object]$response,
        [object]$content,
        [Exception]$innerException
    ) : base(
        [string]$message,
        [object]$response,
        [object]$content,
        [System.Net.HttpStatusCode]429,
        [Exception]$innerException
    ) {}
}

class QuotaLimitExceededException : RateLimitExceededException {
    QuotaLimitExceededException (
        [string]$message,
        [object]$response,
        [object]$content,
        [Exception]$innerException
    ) : base(
        [string]$message,
        [object]$response,
        [object]$content,
        [Exception]$innerException
    ) {}
}
