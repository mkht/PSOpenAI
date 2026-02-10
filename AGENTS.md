## Code Style
- Follow the PSScriptAnalyzer rules
- Use `Invoke-ScriptAnalyzer -Settings PSScriptAnalyzerSettings.psd1` to check your code against the project's settings
- When you create a new file, should use CRLF line endings and UTF-8 encoding.

## Testing
- Run `Invoke-Pester -Tag Offline` (All tests) or `Invoke-Pester -Tag Offline -Path <PathToTest>` (Specific test) to run the tests
- Ignore warning messages in tests. it's normal to have some warnings
- It will spend long time to run all tests, so run only the ones you need
- When you edit only comments, readme, or other non-code files, you can skip the tests

## Documentation
- Update the cmdlet help files in `/Docs` if you add new parameters or change the behavior of existing cmdlets
- After updating the help files, run `New-ExternalHelp -Path ./Docs/ -OutputPath ./PSOpenAI-Help.xml -Force` to build the help xml file.

## References
- This project is PowerShell wrapper for OpenAI API, so you can refer to the [OpenAI API documentation](https://platform.openai.com/docs/api-reference) for details on how the API works.

## Environment
- When you execute any command, ALWAYS use PowerShell commands. DO NOT use bash commands like `rg`, `grep`, `sed` etc.
