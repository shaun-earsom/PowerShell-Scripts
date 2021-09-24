<#
.SYNOPSIS
	Insures hosts file has the correct entry for the target server Octopus is working on.

.DESCRIPTION
    This script will do the following on the script execution server:
    1. Open a Powershell instance in admin mode.
    2. Comments any un-commented lines in the hosts file.
    3. Uncomments host entry we need for this run.  If it doesn't exist, it is created.
    4. Exit the Powershell instance.

.PARAMETER octoHost
	Passed to Get-Content | Set-Content to alter the hosts file.

.PARAMETER elevated
	Check if we're running as admin.

.EXAMPLE
    ".\hostsControl.ps1 #{serverip} #{wwwdomain}"

.NOTES
    Script Name: hostsControl
    By: Shaun Earsom
#>
<#
Define Variables
    octoHost    = ServerIP + Domain
    elevated    = To determine if we're an admin.
    hostsPath   = path to hosts file.
    hostsEntry  = used to make hosts entries.
    hostsActive = Array of existing active hosts entries.
    pattern     = RegEx pattern of un-commented hosts entries (IP + domain/comment)
#>
param(
    [string]$octoHost
    [switch]$elevated
)

$hostsPath = "$env:SystemDrive\Windows\System32\Drivers\etc\hosts"
$hostsActive = @()
$pattern = '^(?<IP>\d{1,3}(\.\d{1,3}){3})\s+(?<Host>.+)$'

<#
Define Functions
    Test-Admin          = Check if we're admin.
    Open-PSConnection   = Opens a Powershell instance as admin.
    Get-HostsEntries    = Reads hosts file and returns un-commented hosts file entries.
    Test-HostsEntries   = Error corrects if there's too many hosts entries, and comments them.
    Set-UpdateHosts     = Sets the hosts entry.
#>
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Open-PSConnection {
    if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        Write-Error "hostsControl.ps1 - Tried to create elevated Powershell instance, did not work, aborting..."
    }else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated -action "{1}"' -f ($myinvocation.MyCommand.Definition,$action))
        }
    exit
    }
    Write-Host "hostsControl.ps1 - Elevated instance of Powershell created."
}

function Get-HostsEntries {   
    (Get-Content -Path $hostsPath)  | ForEach-Object {
        If ($_ -match $pattern) {
            $hostsActive += "$($matches.IP) $($matches.Host)"
        }
    }
    
    Write-Host "hostsControl.ps1 - Found the following host entries:"
    for ($i = 0; $i -le ($hostsActive.length - 1); $i += 1) {
        Write-Host "hostsControl.ps1 - $($hostsActive[$i])"
    }
}

function Test-HostsEntries {
    if ($hostsActive.length -ge 1) {
        Write-Host "hostsControl.ps1 - Active hosts entries found, commenting them..."
        for ($i = 0; $i -le ($hostsActive.length - 1); $i += 1) {
            (Get-Content $hostsPath -Raw) -replace "$($hostsActive[$i])", "#$($hostsActive[$i])" | Set-Content -Path $hostsPath
            Write-Information "hostsControl.ps1 - Commented $($hostsActive[$i])"
        }
        Write-Host "hostsControl.ps1 - Finished.  All previous hosts entries have been commented."
    }else {
        Write-Host "hostsControl.ps1 - No active hosts entries found, proceeding..."
    }
}

function Set-UpdateHosts {
    if (Select-String -Path $hostsPath -Pattern "#$($octoHost)" -Quiet){
        (Get-Content $hostsPath -Raw) -replace "#$($octoHost)", "$($octoHost)" | Set-Content -Path $hostsPath
    }else {
        Add-Content -path $hostsPath -value $octoHost;
    }
}

# Run Program
Test-Admin
Open-PSConnection
Get-HostsEntries
Test-HostsEntries
Set-UpdateHosts 

# Done! Close PS Instance.
Stop-Process -Name "powershell"
