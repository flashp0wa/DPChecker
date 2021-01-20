<#
.SYNOPSIS

.DESCRIPTION
The script check the distribution points of the envireonment and sends an email if offline or the drive free space drops below 5 GB
.PARAMETER DemoParam1
    

.PARAMETER DemoParam2
    

.EXAMPLE
   

.EXAMPLE
    

.NOTES
    Author: flashp0wa
    Last Edit: 11/3/2020
    Version 1.0

#>

#Create Tracelog
$global:LOGFILE = "C:\Windows\DPChecker.log"
$global:bVerbose = $True


function Write-TraceLog
{                                       
    [CmdletBinding()]
    PARAM(
     [Parameter(Mandatory=$True)]                     
	    [String]$Message,                     
	    [String]$LogPath = $LOGFILE, 
     [validateset('Info','Error','Warn')]   
	    [string]$severity,                     
	    [string]$component = $((Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name),
        [long]$logsize = 5 * 1024 * 1024,
        [switch]$Info
	)                

    $Verbose = [bool]($PSCmdlet.MyInvocation.BoundParameters['Verbose'])
    Switch ($severity)
    {
        'Error' {$sev = 3}
        'Warn'  {$sev = 2}
        default {$sev = 1}
    }

    If (($Verbose -and $bVerbose) -or ($Verbose -eq $false)) {
	    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"                     
	    $WhatTimeItIs= Get-Date -Format "HH:mm:ss.fff"                     
	    $Dizzate= Get-Date -Format "MM-dd-yyyy"                     
	
	    "<![LOG[$Message]LOG]!><time=$([char]34)$WhatTimeItIs$($TimeZoneBias.bias)$([char]34) date=$([char]34)$Dizzate$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$sev$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath $LogPath -Append -NoClobber -Encoding default
    }

    If ($bVerbose) {write-host $Message}

    $LogPath = $LogPath.ToUpper()
    $i = Get-Item -Path $LogPath
    #$i.Length
    #$i.Length
    If ($i.Length -gt $logsize)
    {
        $backuplog = $LogPath.Replace(".LOG", ".LO_")
        If (Test-Path $backuplog)
        {
            Remove-Item $backuplog
        }
        Move-Item -Path $LogPath -Destination $backuplog
    } 

}

Write-TraceLog -Message "Starting Script" -severity Info -component "DP Checker"

Write-TraceLog -Message "Reading DP List" -severity Info -component "DP Checker"
Import-Module 'X:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location ABC:
    $DPList = (Get-CMDistributionPointInfo).ServerName
#Set-Location C:
Write-TraceLog -Message "DP List successfuly read" -severity Info -component "DP Checker"


foreach ($DP in $DPList) {

    Write-TraceLog -Message "Pinging $DP..." -severity Info -component "DP Checker"
    $Online = Test-Connection $DP

    if (!$Online) {
        switch ($DP) {
            
        }
        Write-TraceLog -Message "$DP Offline - Notification Email Sent" -severity Info -component "DP Checker" 
    }
    else {
        Write-TraceLog -Message "Checking $DP" -severity Info -component "DP Checker"
        $DrivesGB = Invoke-Command -computername $DP -ScriptBlock {
            Get-PSDrive | Where-Object {$_.Name -eq "c" -or $_.Name -eq "e"} | Select-Object Free | ForEach-Object {[math]::round($_.Free/1Gb, 0)}
        }
            foreach ($drive in $DrivesGB) {

                if ($drive -lt "5") {
                    $IsLow = "Yes"
                }
            }

            if ($IsLow -eq "Yes") {
                Send-MailMessage -To "" -From ""  -Subject "Low disk free space on $DP" -Body "The disk space is running low on $DP, please check." -SmtpServer "" -Port 25
                Write-TraceLog -Message "Disk space is low on $DP" -severity Info -component "DP Checker"
                $IsLow = "No"
            }
            else {
                Write-TraceLog -Message "$DP OK" -severity Info -component "DP Checker"
            }
    }
}