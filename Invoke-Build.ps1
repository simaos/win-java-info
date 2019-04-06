param([switch]$AppVeyor=$false)
$ErrorActionPreference="Stop"

function Confirm-BuildEnvironment{
    Param(  [Parameter(mandatory=$true)][string]$ModuleName,
            [Parameter(mandatory=$true)][string]$CommandName)
    Write-Output "Is module '$ModuleName' available?"
    Write-Output "  (check by looking for command '$CommandName')"
    if ((Get-Command | Where-Object {$_.Name -eq "$CommandName"}).Length -eq 0)
    {
        Write-Output "Cannot find command '$CommandName'"
        Write-Output "Try to install module '$ModuleName'"
        Install-Module -Name "$ModuleName"
        if ((Get-Command | Where-Object {$_.Name -eq "$CommandName"}).Length -eq 0)
        {
            Write-Output "Still cannot find command '$CommandName'"
            Write-Output "Assume module '$ModuleName' install failed"
            Write-Error "Aborting build"
            throw "Could not find or install module '$ModuleName'"
        }
    }
}

Write-Output "Checking build environment for required modules"
Confirm-BuildEnvironment -ModuleName "PSScriptAnalyzer" -CommandName "Invoke-ScriptAnalyzer"
Confirm-BuildEnvironment -ModuleName "Pester" -CommandName "Invoke-Pester"
Write-Output "Starting build"
if ($AppVeyor)
{
    Write-Output "  (assuming AppVeyor build CI server)"
}
Write-Output "Checking for clean static analysis findings from PSScriptAnalyzer"
$result = Invoke-ScriptAnalyzer -Path "." -Recurse
if ($result.Length -gt 0)
{
    Write-Output $result
    throw "Build failed. Found $($result.Length) static analysis issue(s)"
}
Write-Output "Static analysis findings clean"
Write-Output "Running tests"
$resultsPath = ".\TestResults.xml"
Invoke-Pester -EnableExit -OutputFormat NUnitXml -OutputFile $resultsPath
Write-Output "Test results can be found in '$resultsPath"
if ($AppVeyor)
{
    Write-Output "Uploading test results to AppVeyor"
    $url = "https://ci.AppVeyor.com/api/testresults/nunit/$($env:AppVeyor_JOB_ID)"
    (New-Object 'System.Net.WebClient').UploadFile($url, (Resolve-Path $resultsPath))
}
Write-Output "Build complete"