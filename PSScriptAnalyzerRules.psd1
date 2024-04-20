@{
    Severity     = @('Error')
    IncludeRules = @(
        'PSUseCompatibleSyntax',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidDefaultValueSwitchParameter',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSAvoidUsingUserNameAndPassWordParams',
        'PSAvoidUsingPlaintTextForPassword',
        'PSAvoidUsingWMICmdlet',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSPossibleIncorrectComparisonWithNull',
        'PSUseApprovedVerbs',
        'PSUseOutputTypeCorrectly',
        'PSShouldProcess',
        'PSUserToExportFieldsInManifest',
        'PSUseSingularNouns',
        'PSAvoidUsingInvokeExpression',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseCore',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSUseConsistentWhitespace',
        'PSUseConsistentIndentation',
        'PSAlignAssignmentStatement'
        # 'PSUseCorrectCasing' ## We do not like the use of -EQ, prefer -eq
    )
    Rules        = @{
        PSUseCompatibleSyntax      = @{
            Enable        = $true
            TargetVersion = @(
                '5.1',
                '7.2'
            )
        }

        PSPlaceOpenBrace           = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace          = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSUseConsistentIndentation = @{
            Enable              = $true
            Kind                = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize     = 4
        }

        PSUseConsistentWhitespace  = @{
            Enable          = $true
            CheckInnerBrace = $true
            CheckOpenBrace  = $true
            CheckOpenParen  = $true
            CheckOperator   = $false
            CheckPipe       = $true
            CheckSeparator  = $true
        }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }

        PSUseCorrectCasing         = @{
            Enable = $true
        }
    }
}
