Describe 'Get-JavaInfo' {
    It 'Should always output something' {
        $output = .\Get-JavaInfo.ps1
        $output.Length | Should BeGreaterThan 0
    }
}