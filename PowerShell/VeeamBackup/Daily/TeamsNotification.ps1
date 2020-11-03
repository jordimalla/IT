<#
        .SYNOPSIS
        PRTG Veeam Advanced Sensor
  
        .DESCRIPTION
        Advanced Sensor will Report Statistics about Backups during last 24 Hours and Actual Repository usage. It will then convert them into JSON Card and send to teams chanel
	
        .Notes
        NAME:  TeamsNotification.ps1
        ORIGINAL NAME: PRTG-VeeamBRStats.ps1
        LASTEDIT: 16/06/2020
        VERSION: 1.0
        KEYWORDS: Veeam, PRTG, Teams
   
        .Link
        http://mycloudrevolution.com/
        Minor Edits and JSON output for Grafana by https://jorgedelacruz.es/
        Minor Edits from JSON to Influx for Grafana by r4yfx
		    Minor Edits from to send for Teams by Jordi Malla
 
 #Requires PS -Version 3.0
 #Requires -Modules VeeamPSSnapIn    
 #>
[cmdletbinding()]
param(
    [Parameter(Position=0, Mandatory=$false)]
        [string] $BRHost = "127.0.0.1",
    [Parameter(Position=1, Mandatory=$false)]
        $reportMode = "24", # Weekly, Monthly as String or Hour as Integer
    [Parameter(Position=2, Mandatory=$false)]
        $repoCritical = 10,
    [Parameter(Position=3, Mandatory=$false)]
        $repoWarn = 20
  
)
# You can find the original code for PRTG here, thank you so much Markus Kraus - https://github.com/mycloudrevolution/Advanced-PRTG-Sensors/blob/master/Veeam/PRTG-VeeamBRStats.ps1
# Big thanks to Shawn, creating a awsome Reporting Script:
# http://blog.smasterson.com/2016/02/16/veeam-v9-my-veeam-report-v9-0-1/

#region Import functions
Import-Module "$PSScriptRoot\Helpers"
#endregion

#region: Start Load VEEAM Snapin (if not already loaded)
if (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
	if (!(Add-PSSnapin -PassThru VeeamPSSnapIn)) {
		# Error out if loading fails
		Write-Error "`nERROR: Cannot load the VEEAM Snapin."
		Exit
	}
}
#endregion

#region: Functions
Function Get-Body{
[CmdletBinding()]
    param (
        [Parameter(Position=0)] $BKOk,
        [Parameter(Position=1)] $BKW,
        [Parameter(Position=2)] $BKF,
        [Parameter(Position=3)] $BKCopyOk,
        [Parameter(Position=4)] $BKCopyW,
        [Parameter(Position=5)] $BKCopyF,
        [Parameter(Position=6)] $BKCopyRun,
        [Parameter(Position=7)] $BKCopyIdle,
        [Parameter(Position=8)] $BKCintaOk,
        [Parameter(Position=9)] $BKCintaW,
        [Parameter(Position=10)] $BKCintaF,
        [Parameter(Position=11)] $BKCintaRun,
        [Parameter(Position=12)] $BKCintaWait,
        [Parameter(Position=13)] $BKCintaIdle
    )
    Begin {
        $bodyOut = ""
    }
    Process {
        # Get the config from our config file
	    $config = (Get-Content "$PSScriptRoot\config\conf.json") -Join "`n" | ConvertFrom-Json

	    #region Load icon
	    $ico_Backup = ""
	    $ico_BCopy = ""
	    $ico_BCinta = ""

	    if($BKF -gt 0)
	    {
		    $ico_Backup = $config.icon_fail
	    }
	    elseif($BKW -gt 0)
	    {
		    $ico_Backup = $config.icon_warning
	    }
	    else
	    {
		    $ico_Backup = $config.icon_ok
	    }	

	    if($BKCopyF -gt 0)
	    {
		    $ico_BCopy = $config.icon_fail
	    }
	    elseif($BKCopyW -gt 0)
	    {
		    $ico_BCopy = $config.icon_warning
	    }
	    else
	    {
		    $ico_BCopy = $config.icon_ok
	    }	

	    if($BKCintaF -gt 0)
	    {
		    $ico_BCinta = $config.icon_fail
	    }
	    elseif($BKCintaW -gt 0)
	    {
		    $ico_BCinta = $config.icon_warning
	    }
	    else
	    {
		    $ico_BCinta = $config.icon_ok
	    }
	    #endregion

	    #region sumary
	    $sumary = ""

	    if(($BKCintaF -gt 0) -Or ($BKCopyF -gt 0) -Or ($BKF -gt 0))
	    {
		    $sumary = "Copies de seguretat Veeam Failed"
	    }
	    elseif(($BKCintaW -gt 0) -Or ($BKCopyW -gt 0) -Or ($BKW -gt 0))
	    {
		    $sumary = "Copies de seguretat Veeam Warning"
	    }
	    else
	    {
		    $sumary = "Copies de seguretat Veeam Ok"
	    }
	    #endregion

	    #region Body
	    $bodyOut = @"
	    {
            "@context": "https://schema.org/extensions",
            "@type": "MessageCard",
            "themeColor": "0072C6",
            "summary": "$sumary",
		    "title": "Veeam Backup",
            "sections": [{
				"activityTitle": "**Backup**",
				"activityImage": "$ico_Backup",
				"facts":[{
					"name": "Succes:",
					"value": "$BKOk"
				}, {
					"name": "Warning:",
					"value": "$BKW"
				}, {
					"name": "Failed:",
					"value": "$BKF"
				}]
			}, {
				"activityTitle": "**Backup Copy**",
				"startGroup" : true,
				"activityImage" : "$ico_BCopy",
				"facts": [{
					"name": "Succes:",
					"value": "$BKCopyOk"
				}, {
					"name": "Warning:",
					"value": "$BKCopyW"
				}, {
					"name": "Failed:",
					"value": "$BKCopyF"
				}, {
					"name": "Running:",
					"value": "$BKCopyRun"
				}, {
					"name": "Idle:",
					"value": "$BKCopyIdle"
				}]
			}, {
				"activityTitle": "**Backup Cinta**",
				"activityImage": "$ico_BCinta",
				"facts": [{
					"name": "Succes:",
					"value": "$BKCintaOk"
				}, {
					"name": "Warning:",
					"value": "$BKCintaW"
				}, {
					"name": "Failed:",
					"value": "$BKCintaF"
				}, {
					"name": "Running:",
					"value": "$BKCintaRun"
				}, {
					"name": "Waiting:",
					"value": "$BKCintaWait"
				}, {
					"name": "Idle:",
					"value": "$BKCintaIdle"
				}]
			}],
		    "potentialAction": [{
				"@type": "OpenUri",
				"name": "View details",
				"targets": [{
						"os": "default",
						"uri": "http://svrdocker:3000/d/ha4f9kKZk/veeam-grafana?orgId=1&from=now-7d&to=now&refresh=5s"
				}]
			}]
	    }
"@
        #endregion	
    }	
    End {
        $bodyOut
    }
}
#endregion

#region Get the config from our config file
$config = (Get-Content "$PSScriptRoot\config\conf.json") -Join "`n" | ConvertFrom-Json
#endregion

#region Logging
if($config.Debug_Log) {
	Start-Logging "$PSScriptRoot\log\debug.log"
}
#endregion

#region: Start BRHost Connection
$OpenConnection = (Get-VBRServerSession).Server
if($OpenConnection -eq $BRHost) {
	
} elseif ($OpenConnection -eq $null ) {
	
	Connect-VBRServer -Server $BRHost
} else {
    
    Disconnect-VBRServer
   
    Connect-VBRServer -Server $BRHost
}

$NewConnection = (Get-VBRServerSession).Server
if ($NewConnection -eq $null ) {
	Write-Error "`nError: BRHost Connection Failed"
	Exit
}
#endregion

#region: Convert mode (timeframe) to hours
If ($reportMode -eq "Monthly") {
        $HourstoCheck = 720
} Elseif ($reportMode -eq "Weekly") {
        $HourstoCheck = 168
} Else {
        $HourstoCheck = $reportMode
}
#endregion

#region: Collect and filter Sessions
$allSesh = Get-VBRBackupSession         # Get all Sessions (Backup/BackupCopy/Replica)
$seshListBk = @($allSesh | ?{($_.CreationTime -ge (Get-Date).AddHours(-$HourstoCheck)) -and $_.JobType -eq "Backup"})           # Gather all Backup sessions within timeframe
$seshListBkc = @($allSesh | ?{($_.CreationTime -ge (Get-Date).AddHours(-$HourstoCheck)) -and $_.JobType -eq "BackupSync"})      # Gather all BackupCopy sessions within timeframe
#endregion

#region: Collect Jobs
$allJobsTp = @(Get-VBRTapeJob)
#endregion

#region: Get all Tape Backup Sessions
$allSessTp = @()
If ($allJobsTp) {
  Foreach ($tpJob in $allJobsTp){
    $tpSessions = [veeam.backup.core.cbackupsession]::GetByJob($tpJob.id)
    $allSessTp += $tpSessions
  }
}
#endregion

#region: Gather all Tape Backup Sessions within timeframe
# Only report on the following Tape Backup Job(s)
#$tapeJob = @("Tape Backup Job 1","Tape Backup Job 3","Tape Backup Job *")
$tapeJob = @("")
# Only show last Session for each Tape Backup Job
$onlyLastTp = $false

$sessListTp = @($allSessTp | ?{$_.EndTime -ge (Get-Date).AddHours(-$HourstoCheck) -or $_.CreationTime -ge (Get-Date).AddHours(-$HourstoCheck) -or $_.State -match "Working|Idle"})
If ($tapeJob -ne $null -and $tapeJob -ne "") {
  $allJobsTpTmp = @()
  $sessListTpTmp = @()
  Foreach ($tpJob in $tapeJob) {
    $allJobsTpTmp += $allJobsTp | ?{$_.Name -like $tpJob}
    $sessListTpTmp += $sessListTp | ?{$_.JobName -like $tpJob}
  }
  $allJobsTp = $allJobsTpTmp | sort Id -Unique
  $sessListTp = $sessListTpTmp | sort Id -Unique
}
If ($onlyLastTp) {
  $tempSessListTp = $sessListTp
  $sessListTp = @()
  Foreach($job in $allJobsTp) {
    $sessListTp += $tempSessListTp | ?{$_.Jobname -eq $job.name} | Sort-Object EndTime -Descending | Select-Object -First 1
  }
}
#endregion

#region: Get Backup session informations
$totalxferBk = 0
$totalReadBk = 0
$seshListBk | %{$totalxferBk += $([Math]::Round([Decimal]$_.Progress.TransferedSize/1GB, 0))}
$seshListBk | %{$totalReadBk += $([Math]::Round([Decimal]$_.Progress.ReadSize/1GB, 0))}
#endregion

#region: Preparing Backup Session Reports
$successSessionsBk = @($seshListBk | ?{$_.Result -eq "Success"})
$warningSessionsBk = @($seshListBk | ?{$_.Result -eq "Warning"})
$failsSessionsBk = @($seshListBk | ?{$_.Result -eq "Failed"})
$runningSessionsBk = @($allSesh | ?{$_.State -eq "Working" -and $_.JobType -eq "Backup"})
$failedSessionsBk = @($seshListBk | ?{($_.Result -eq "Failed") -and ($_.WillBeRetried -ne "True")})
#endregion

#region:  Preparing Backup Copy Session Reports
$successSessionsBkC = @($seshListBkC | ?{$_.Result -eq "Success"})
$warningSessionsBkC = @($seshListBkC | ?{$_.Result -eq "Warning"})
$failsSessionsBkC = @($seshListBkC | ?{$_.Result -eq "Failed"})
$runningSessionsBkC = @($allSesh | ?{$_.State -eq "Working" -and $_.JobType -eq "BackupSync"})
$IdleSessionsBkC = @($allSesh | ?{$_.State -eq "Idle" -and $_.JobType -eq "BackupSync"})
$failedSessionsBkC = @($seshListBkC | ?{($_.Result -eq "Failed") -and ($_.WillBeRetried -ne "True")})
#endregion

#region: Preparing Tape Reports ...
# Get Tape Backup Session information
$totalXferTp = 0
$totalReadTp = 0
$sessListTp | %{$totalXferTp += $([Math]::Round([Decimal]$_.Progress.TransferedSize/1GB, 2))}
$sessListTp | %{$totalReadTp += $([Math]::Round([Decimal]$_.Progress.ReadSize/1GB, 2))}
$idleSessionsTp = @($sessListTp | ?{$_.State -eq "Idle"})
$successSessionsTp = @($sessListTp | ?{$_.Result -eq "Success"})
$warningSessionsTp = @($sessListTp | ?{$_.Result -eq "Warning"})
$failsSessionsTp = @($sessListTp | ?{$_.Result -eq "Failed"})
$workingSessionsTp = @($sessListTp | ?{$_.State -eq "Working"})
$waitingSessionsTp = @($sessListTp | ?{$_.State -eq "WaitingTape"})
#endregion

#region: Send to Teams
$body = Get-Body $successSessionsBk.Count $warningSessionsBk.Count $failsSessionsBk.Count $successSessionsBkC.Count $warningSessionsBkC.Count $failsSessionsBkC.Count $runningSessionsBkC.Count $IdleSessionsBkC.Count  $successSessionsTp.Count $warningSessionsTp.Count $failsSessionsTp.Count $workingSessionsTp.Count $waitingSessionsTp.Count $idleSessionsTp.Count

$uri = $config.webhook
#region: Debug
if($config.debug_log){
    Write-LogMessage 'Info' $uri
    Write-LogMessage 'Info' $body
}
#endregion
Invoke-RestMethod -uri $uri -Method Post -body $body -ContentType 'application/json'
#endregion
