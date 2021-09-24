
# Script Name: hostModify
# By: Shaun Earsom
# Version: 0.2
#
# What does this thing do?
# - Finds and replaces ip entries inside the hosts file.
# - Comments/Uncomments by commenting the line with '#'.
# Example: .\hostModify.ps1 -action 'activate' -findip '###.###.###.###' -replaceip '###.###.###.###'
#
# Define Variables
# $action = Determine if we're adding comment hashes or removing them. Can only be 'activate' or 'deactivate'.
# $findip = IP we're trying to find in the HOSTS file.
# $replaceip = IP we're trying to replace it with. (note: As of this version, if you don't want to replace the IP make both findIp and replaceIP the same IP.)
# $findipV = Validated find IP is an IPv4 address.
# $replaceIpV = Validated replace IP is an IPv4 address.
# $elevated = Switch used in determining if we have admin rights.
# $pattern = RegEx used to validate IPv4 number range match.
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string]$action,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string]$findip,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string]$replaceip,
    [switch]$elevated
)

# Validate $findip and $replaceip are, in fact, IPv4 IP addresses.
$pattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
if ($findip -match $pattern) {
    $findIpV = $findip
} else {
    Write-Output "findip was not an IPv4 address."
}
if ($replaceip -match $pattern) {
    $replaceIpV = $replaceip
} else {
    Write-Output "replaceip was not an IPv4 address"
}

# Build variables for the command.
$comment = '#'
$commentedFind = $comment + $findIpV
$commentedReplace = $comment + $replaceIpV

# Function to check if we're admin
function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Open a powershell screen as admin
if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        Write-Output "tried to elevate, did not work, aborting"
    }else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated -action "{1}"' -f ($myinvocation.MyCommand.Definition,$action))
    }
exit
}
# Should now be running with full privileges

# Add subtract the comment and replace the IP address with the correct one.
if ($action -like 'activate')  {
    (Get-Content C:\Windows\System32\drivers\etc\hosts -Raw) -replace "$($commentedFind)", "$($replaceIpV)" | Set-Content -Path C:\Windows\System32\drivers\etc\hosts
    Start-Sleep 2
    Write-Output $action
}elseif($action -like 'deactivate'){
    (Get-Content C:\Windows\System32\drivers\etc\hosts -Raw) -replace "$($findIpV)", "$($commentedReplace)" | Set-Content -Path C:\Windows\System32\drivers\etc\hosts
    Start-Sleep 2
    Write-Output $action
}

Start-Sleep 2

Stop-Process -Name "powershell"
© 2021 GitHub, Inc.
