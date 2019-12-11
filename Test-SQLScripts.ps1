# Add items to the $verifcationTests hashtable, in order to add tests. 
# The hash's key is the Microsoft.SqlServer.TransactSql.ScriptDom.TSqlStatement descendant class we are checking, and the value is the Pester test assumption
# If you add a statement-type and get a Parser Key missing warning, add it to the Get-SqlServerDomParserKeys function.
$verifcationTests = @{
    AlterTableAlterColumnStatement      = "The script does not alter the column of any tables";
    AlterTableDropTableElementStatement = "The script does not drop any table elements";
    DropTableStatement                  = "The script does not drop any tables";
}

Describe "When migrating SQL schema changes to the database" {
    Import-Module $PSScriptRoot/Modules/SqlScriptParser/Get-SqlServerDomParserKeys.psm1
    Import-Module $PSScriptRoot/Modules/SqlScriptParser/Invoke-SqlScriptParser.psm1
        
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module -Name Assert -Scope CurrentUser -SkipPublisherCheck
    Import-Module Assert
    
    function Test-ViolatingStatements {
        param (
            [Parameter(Mandatory = $true)][string] $StatementType
        )
        $found = $statements | Where-Object StatementType -Like $StatementType

        if ($found) {
            $customMessage = "Found $($found.Count) instances of $($found[0].StatementType):"
            foreach ($item in $found) {
                $customMessage = $customMessage + "`r`n`ton line #$($item.LineNumber): $($item.Text)"
            }
        }
        $found.Count | Assert-Equal -Expected 0 -CustomMessage $customMessage
    }

    if (!$Env:PathToSql) {
        $Env:PathToSql = $null
    }
    if (!$Env:PathToScriptDomLibrary) {
        $Env:PathToScriptDomLibrary = $null
    }
    if (!$Env:UseQuotedIdentifier) {
        $Env:UseQuotedIdentifier = $null
    }
    Write-Host "Files: $Env:PathToSql"

    $results = (Get-ChildItem $Env:PathToSql) | Invoke-SqlScriptParser `
        -PathToScriptDomLibrary $Env:PathToScriptDomLibrary `
        -UseQuotedIdentifier $Env:UseQuotedIdentifier

    $statements = $results.Batches.Statements

    $verifcationTests.Keys | ForEach-Object {
        It $verifcationTests.Item($_) {
            Test-ViolatingStatements -StatementType $_
        }
    }
}