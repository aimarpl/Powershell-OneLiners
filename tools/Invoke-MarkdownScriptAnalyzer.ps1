#Requires -Version 5.1

<#
.SYNOPSIS
    Runs PSScriptAnalyzer over the PowerShell examples embedded in Markdown.

.DESCRIPTION
    The one-liners in this repository live inside ```powershell fenced code
    blocks, not in .ps1 files. Pointing an analyzer at *.ps1 therefore finds
    nothing and reports success, which is why this script extracts each fenced
    block and analyzes it instead.

    Findings are reported against the Markdown file and the real line number of
    the offending line, so a failure points at the example to fix.

.PARAMETER Path
    Directory to search for Markdown files. Defaults to the repository root.

.PARAMETER Severity
    Severities to report. Defaults to Error and Warning.

.PARAMETER ExcludeRule
    Analyzer rules to skip. Defaults to the rules that do not apply to
    illustrative one-liners.

.EXAMPLE
    .\tools\Invoke-MarkdownScriptAnalyzer.ps1

    Analyzes every example in the repository.

.EXAMPLE
    .\tools\Invoke-MarkdownScriptAnalyzer.ps1 -Path PSOneLiners -Severity Error

    Checks a single directory for errors only.

.OUTPUTS
    Writes findings to the host. Exits 1 when any finding is reported.
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Path = (Join-Path -Path $PSScriptRoot -ChildPath '..'),

    [ValidateSet('Error', 'Warning', 'Information')]
    [string[]]$Severity = @('Error', 'Warning'),

    [string[]]$ExcludeRule = @(
        # Examples are deliberately short and interactive; these rules target
        # production scripts and would fire on almost every one-liner.
        'PSAvoidUsingWriteHost',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingPositionalParameters',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingPlainTextForPassword',
        'PSReviewUnusedParameter',
        # Example host names are documented placeholders (server01.example.com).
        # The rule exists to stop real infrastructure names leaking, which the
        # publishing review already covers.
        'PSAvoidUsingComputerNameHardcoded'
    )
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    throw 'PSScriptAnalyzer is not installed. Install-Module PSScriptAnalyzer -Scope CurrentUser'
}
Import-Module PSScriptAnalyzer

function Get-PowerShellBlock {
    <#
        Returns each ```powershell fenced block in a Markdown file, with the
        line number where its code starts so findings map back to the source.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory)][string]$MarkdownPath)

    $lines = Get-Content -Path $MarkdownPath
    $inBlock = $false
    $buffer = [System.Collections.Generic.List[string]]::new()
    $startLine = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if (-not $inBlock -and $line -match '^\s*```\s*(powershell|ps1)\s*$') {
            $inBlock = $true
            $buffer.Clear()
            # Code starts on the line after the opening fence; +2 converts the
            # zero-based index into a one-based line number.
            $startLine = $i + 2
            continue
        }

        if ($inBlock -and $line -match '^\s*```\s*$') {
            $inBlock = $false
            if ($buffer.Count -gt 0) {
                [PSCustomObject]@{
                    StartLine = $startLine
                    Code      = ($buffer -join [Environment]::NewLine)
                }
            }
            continue
        }

        if ($inBlock) {
            $buffer.Add($line)
        }
    }
}

$root = (Resolve-Path -Path $Path).Path
$markdownFiles = @(Get-ChildItem -Path $root -Filter '*.md' -Recurse -File |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })

if ($markdownFiles.Count -eq 0) {
    Write-Output 'No Markdown files found.'
    exit 0
}

$findings = [System.Collections.Generic.List[PSCustomObject]]::new()
$blockCount = 0

foreach ($file in $markdownFiles) {
    $relative = $file.FullName.Substring($root.Length).TrimStart('\', '/')

    foreach ($block in Get-PowerShellBlock -MarkdownPath $file.FullName) {
        $blockCount++

        $results = Invoke-ScriptAnalyzer -ScriptDefinition $block.Code `
            -Severity $Severity -ExcludeRule $ExcludeRule

        foreach ($result in $results) {
            $findings.Add([PSCustomObject]@{
                File     = $relative
                Line     = $block.StartLine + $result.Line - 1
                Severity = $result.Severity
                Rule     = $result.RuleName
                Message  = $result.Message
            })
        }
    }
}

Write-Output "Analyzed $blockCount PowerShell example(s) in $($markdownFiles.Count) Markdown file(s)."

if ($findings.Count -eq 0) {
    Write-Output 'PSScriptAnalyzer: clean'
    exit 0
}

Write-Output ''
foreach ($finding in $findings | Sort-Object File, Line) {
    Write-Output ('{0}:{1} {2} {3}' -f $finding.File, $finding.Line, $finding.Severity, $finding.Rule)
    Write-Output ('    {0}' -f $finding.Message)
}

Write-Output ''
Write-Output "PSScriptAnalyzer reported $($findings.Count) finding(s)."
exit 1
