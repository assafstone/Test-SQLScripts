[cmdletbinding()]
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)
    ] [System.IO.FileInfo] $Files,
    [Parameter(Mandatory = $false)] [string] $PathToScriptDomLibrary = $null,
    [Parameter(Mandatory = $false)] [string] $UseQuotedIdentifier = $true
)

Import-Module .\Modules\SqlScriptParser\Get-SqlServerDomParserKeys.psm1
Import-Module .\Modules\SqlScriptParser\Invoke-SqlScriptParser.psm1

$Files | Invoke-SqlScriptParser `
    -PathToScriptDomLibrary $PathToScriptDomLibrary `
    -UseQuotedIdentifier $UseQuotedIdentifier