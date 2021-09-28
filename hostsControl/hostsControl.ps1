<#
.SYNOPSIS
	Insures hosts file has the correct entry for the target server Octopus is working on.

.DESCRIPTION
    This script will do the following:
    1. Opens Admin Powershell Instance
    2. Finds entries in hosts
    3. Creates array of entries
    4. Comments all found entries
    5. Searches for commented entry
    6. If Commented but desired entry is found
    7. Uncomments desired entry
    8. Else, Create desired entry.

.EXAMPLE
    ".\hostsControl.ps1" *NOTE* Designed to only be called by Octopus Deploy, ran on worker node.

.NOTES
    Script Name: hostsControl
    By: Shaun Earsom
#>
<#
Define Variables
    serverip    = global variable from Octopus
    wwwdomain   = global variable from Octopus
    octoHost    = ServerIP + (space) + Domain
    hostsPath   = path to hosts file.
    hostsActive = Array of existing active hosts entries.
    pattern     = RegEx pattern of un-commented hosts entries (IP + domain/comment)
#>

# Check if globals have values.  If so, create octoHost.
if (($serverip -eq $null) -or ($wwwdomain -eq $null)) {
    Write-Error "hostsControl.ps1 - ERROR Serverip or wwwdomain are equal to NULL"
    throw 'hostsControl.ps1 - serverip or wwwdomain are empty.'
} else {
    $octoHost = "$($serverip) $($wwwdomain)"
}

$hostsPath = "$env:SystemDrive\Windows\System32\Drivers\etc\hosts"
$hostsActive = @()
$pattern = '^(?<IP>\d{1,3}(\.\d{1,3}){3})\s+(?<Host>.+)$'

<#
Define Functions
    Open-PSConnection   = Opens a Powershell instance as admin.
    Set-HostsEntries    = Does everything else.
#>

function Open-PSConnection {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
}

function Set-HostsEntries {   
    (Get-Content -Path $hostsPath)  | ForEach-Object {
        If ($_ -match $pattern) {
            $hostsActive += "$($matches.IP) $($matches.Host)"
        }
    }
    Write-Host "hostsControl.ps1 - number of entries in hostsActive: $($hostsActive.length)" #REMOVE
    if ($hostsActive.length -ge 1) {
        Write-Host "hostsControl.ps1 - Found the following host entries:"
        for ($i = 0; $i -le ($hostsActive.length - 1); $i++) {
            Write-Host "hostsControl.ps1 - Commenting: $($hostsActive[$i])"
            (Get-Content $hostsPath -Raw) -replace "$($hostsActive[$i])", "# $($hostsActive[$i])" | Set-Content -Path $hostsPath
        }
        Write-Host "hostsControl.ps1 - All previous hosts entries have been commented."
    }
    if (Select-String -Path $hostsPath -Pattern "# $($octoHost)" -Quiet) {
        Write-Host "hostsControl.ps1 - Uncommenting: $($octoHost)"
        (Get-Content $hostsPath -Raw) -replace "# $($octoHost)", "$($octoHost)" | Set-Content -Path $hostsPath
    }else {
        Write-Host "hostsControl.ps1 - Entry not found, creating..."
        Write-Host "hostsControl.ps1 - Adding to hosts: $($octoHost)"
        Add-Content -path $hostsPath -value $octoHost;
    }
}

# Run Program
Open-PSConnection
Set-HostsEntries

# Done! Octopus will automatically close the PS Instance.
