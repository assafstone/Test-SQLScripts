Describe "Verify SQL scripts do not allow for breaking changes" {
    Import-Module .\Modules\SqlScriptParser\Get-SqlServerDomParserKeys.psm1
    Import-Module .\Modules\SqlScriptParser\Invoke-SqlScriptParser.psm1
    Install-Module -Name Assert
    Import-Module Assert
    
    if (!$Env:Files) {
        $Env:Files = $null
    }
    if (!$Env:PathToScriptDomLibrary) {
        $Env:PathToScriptDomLibrary = $null
    }
    if (!$Env:UseQuotedIdentifier) {
        $Env:UseQuotedIdentifier = $null
    }
    Write-Host "Files: $env:Files"

    $results = (Get-ChildItem $Env:Files) | Invoke-SqlScriptParser `
        -PathToScriptDomLibrary $Env:PathToScriptDomLibrary `
        -UseQuotedIdentifier $Env:UseQuotedIdentifier

    $statements = $results.Batches.Statements

    It "The script does not alter the column of any tables" {
        $found = $statements | Where-Object StatementType -Like "AlterTableAlterColumnStatement"

        if ($found) {
            $customMessage = "Found $($found.Count) instances of $($found[0].StatementType):"
            foreach ($item in $found) {
                $customMessage = $customMessage + "`r`n`ton line #$($item.LineNumber): $($item.Text)"
            }
        }
        # $found | Should -BeNullOrEmpty -because "Line #$($found.LineNumber): $($found.Text)"
        $found.Count | Assert-Equal -Expected 0 -CustomMessage $customMessage
    }

    It "The script does not drop elements of a table" {
        $found = $statements | Where-Object StatementType -Like "AlterTableDropTableElementStatement"

        if ($found) {
            $customMessage = "Found $($found.Count) instances of $($found[0].StatementType):"
            foreach ($item in $found) {
                $customMessage = $customMessage + "`r`n`ton line #$($item.LineNumber): $($item.Text)"
            }
        }
        # $found | Should -BeNullOrEmpty -because "Line #$($found.LineNumber): $($found.Text)"
        $found.Count | Assert-Equal -Expected 0 -CustomMessage $customMessage
    }
}