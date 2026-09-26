#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'ParseResponseObject' {
    Context 'Structured Outputs (offline)' -Tag 'Offline' {
        It 'parses only the final answer when commentary is also present' {
            InModuleScope $script:ModuleName {
                $Response = @'
{
  "id": "resp_structured_output",
  "object": "response",
  "status": "completed",
  "output": [
    {
      "type": "message",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "phase": "commentary",
          "text": "Preparing the structured answer.",
          "annotations": []
        },
        {
          "type": "output_text",
          "phase": "final_answer",
          "text": "{\"answer\":\"42\"}",
          "annotations": []
        }
      ]
    }
  ]
}
'@ | ConvertFrom-Json
                $Messages = [System.Collections.Generic.List[object]]::new()

                { $script:Result = ParseResponseObject -InputObject $Response -Messages $Messages -OutputType ([hashtable]) -ErrorAction Stop } |
                    Should -Not -Throw

                $Result.output[0].content[0].text | Should -BeExactly 'Preparing the structured answer.'
                $Result.output[0].content[0].PSObject.Properties.Name | Should -Not -Contain 'parsed'
                $Result.output[0].content[1].parsed.answer | Should -BeExactly '42'
                $Result.StructuredOutputs | Should -HaveCount 1
                $Result.StructuredOutputs[0].answer | Should -BeExactly '42'
            }
        }

        It 'continues to parse legacy output text without phase' {
            InModuleScope $script:ModuleName {
                $Response = @'
{
  "id": "resp_legacy_structured_output",
  "object": "response",
  "status": "completed",
  "output": [
    {
      "type": "message",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "{\"answer\":\"legacy\"}",
          "annotations": []
        }
      ]
    }
  ]
}
'@ | ConvertFrom-Json
                $Messages = [System.Collections.Generic.List[object]]::new()

                $Result = ParseResponseObject -InputObject $Response -Messages $Messages -OutputType ([hashtable]) -ErrorAction Stop

                $Result.output[0].content[0].parsed.answer | Should -BeExactly 'legacy'
                $Result.StructuredOutputs | Should -HaveCount 1
                $Result.StructuredOutputs[0].answer | Should -BeExactly 'legacy'
            }
        }
    }
}
