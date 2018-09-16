param([switch]$AppVeyor=$false)

function Confirm-AdministratorContext
{
    $administrator = [Security.Principal.WindowsBuiltInRole] "Administrator"
    $identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $identity.IsInRole($administrator)
}

function Use-AdministratorContext
{
    if (-not (Confirm-AdministratorContext))
    {
        $arguments = "& '" + $myinvocation.mycommand.definition + "'"
        Start-Process powershell -Verb runAs -ArgumentList $arguments
        Break
    }
}

function Install-BuildPrerequisite
{
    foreach ($arg in $args)
    {
        Write-Output "Checking build prerequisite module $arg"
        if (-not (Get-Module -Name $arg))
        {
            Write-Output "Requesting elevated permissions to install build prerequisite module $arg"
            Use-AdministratorContext
            Write-Output "Installing build prerequisite module $arg"
            Install-Module -Name $arg -Force -SkipPublisherCheck
        }
        else
        {
            Write-Output "Confirmed already installed build prerequisite module $arg"
        }
    }
}

function Invoke-StaticAnalysis
{
    $result = Invoke-ScriptAnalyzer -Path "." -Recurse
    $result
    if ($result.Length -gt 0)
    {
        throw "Build failed. Found $($result.Length) static analysis issue(s)"
    }
    else
    {
        Write-Output "Static analysis findings clean"
    }
}
function Invoke-Build
{
    if ($AppVeyor)  
    {
        Write-Output "Building in AppVeyor build CI server context"
    }
    else
    {
        Write-Output "Building in normal context"
    }
    Write-Output "Checking static analysis findings"
    Invoke-StaticAnalysis
    Write-Output "Running tests"
    Invoke-Test
}

function Send-TestResult([string]$resultsPath)
{
    $url = "https://ci.AppVeyor.com/api/testresults/nunit/$($env:AppVeyor_JOB_ID)"
    (New-Object 'System.Net.WebClient').UploadFile($url, (Resolve-Path $resultsPath))
}
function Invoke-Test
{
    $resultsPath = ".\TestResults.xml"
    Invoke-Pester -EnableExit -OutputFormat NUnitXml -OutputFile $resultsPath
    if ($AppVeyor)
    {
        Send-TestResult $resultsPath
    }
}

Write-Output "Build starting"
Install-BuildPrerequisite "PSScriptAnalyzer" "Pester"
Invoke-Build
Write-Output "Build complete"