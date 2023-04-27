using System;
using System.Collections.Generic;
using System.Management.Automation;

public class CompletionsAttribute : ArgumentCompleterAttribute
{
    private static ScriptBlock _createScriptBlock(params string[] completions)
    {
        string text = "\"" + string.Join("\",\"", completions) + "\"";
        string code = "param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams);@(" + text + ") -like \"$WordToComplete*\" | Foreach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }";
        return ScriptBlock.Create(code);
    }

    public CompletionsAttribute(params string[] completions) : base(_createScriptBlock(completions))
    {
    }
}
