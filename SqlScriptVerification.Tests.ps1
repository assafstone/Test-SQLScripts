# Add items to the $verificationTests hashtable, in order to add tests. 
# The hash's key is the Microsoft.SqlServer.TransactSql.ScriptDom.TSqlStatement descendant class we are checking, and the value is the Pester test assumption
# If you add a statement-type and get a Parser Key missing warning, add it to the Get-SqlServerDomParserKeys function.

Describe "When migrating SQL schema changes to the database" {
    $violations = @(
        @{violation = 'AlterTableAlterColumnStatement'; reason = 'it should not break backwards compatibility'}, 
        @{violation = 'AlterTableDropTableElementStatement'; reason = 'it should not risk data loss'}, 
        @{violation = 'DropTableStatement'; reason = 'it should not risk data loss'}
    )
    
    Import-Module $PSScriptRoot/Modules/SqlScriptParser/Get-SqlServerDomParserKeys.psm1
    Import-Module $PSScriptRoot/Modules/SqlScriptParser/Invoke-SqlScriptParser.psm1
    
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module -Name Assert -Scope CurrentUser -SkipPublisherCheck
    Import-Module Assert
      
    if (!$Env:PathToSql) {
        $Env:PathToSql = $null
    }
    if (!$Env:PathToScriptDomLibrary) {
        $Env:PathToScriptDomLibrary = $null
    }
    if (!$Env:UseQuotedIdentifier) {
        $Env:UseQuotedIdentifier = $null
    }

    Write-Debug "Files: $Env:PathToSql"
    
    $results = (Get-ChildItem $Env:PathToSql) | Invoke-SqlScriptParser `
    -PathToScriptDomLibrary $Env:PathToScriptDomLibrary `
    -UseQuotedIdentifier $Env:UseQuotedIdentifier
    
    $script:statements = $results.Batches.Statements
   
    It "The script should not have '<violation>' statements, because <reason>." -TestCases $violations {
        param ($violation, $reason)
        $found = $script:statements | Where-Object StatementType -Like $violation
    
        if ($found) {
            $customMessage = "Found $($found.Count) instances of $($found[0].StatementType):"
            foreach ($item in $found) {
                $customMessage = $customMessage + "`r`n`ton line #$($item.LineNumber): $($item.Text)"
            }
        }
        $found.Count | Assert-Equal -Expected 0 -CustomMessage $customMessage
    }
}