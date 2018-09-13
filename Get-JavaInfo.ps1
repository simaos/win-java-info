function Get-FixedDriveName
{
    [System.IO.DriveInfo]::GetDrives() |
        Where-Object { $_.DriveType -eq 'Fixed' } |
        foreach { $_.Name }
}

foreach ($drive in Get-FixedDriveName)
{
    'Searching for Java in ' + $drive
}

