function Get-FixedDriveName
{
    [System.IO.DriveInfo]::GetDrives() |
        Where-Object { $_.DriveType -eq 'Fixed' } |
        ForEach-Object { $_.Name }
}

foreach ($drive in Get-FixedDriveName)
{
    'Searching for Java in ' + $drive
}

