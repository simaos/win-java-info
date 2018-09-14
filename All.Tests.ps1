Describe 'Static Analysis (PSScriptAnalyzer)' {
    It 'Should not report any findings' {
        $result = Invoke-ScriptAnalyzer -Recurse -Path . | Out-String
        $result | Should Be ''
    }
}