[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$type
)

#region Get the config from our config file
$global:config = (Get-Content "$PSScriptRoot\config\vsn.json") -Join "`n" | ConvertFrom-Json
$pathlog = $global:config.Path_Log
$date = Get-Date -format "yyyyMMdd-HHmmss"
$fileName = "$date.log"
$global:log = "$pathlog\$fileName"
#endregion

#region Import functions
Import-Module "$PSScriptRoot\Helpers"
Import-Module SQLPS
#endregion

#region: Backup DB
function DeleteOld(){
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string]$targetpath,
		[Parameter(Mandatory=$true, Position=1)]
        	[int]$days,
		[Parameter(Mandatory=$true, Position=2)]
        	[string]$Extension
	)
    	Set-Location $targetpath\
	$Now = Get-Date
	$LastWrite = $Now.AddDays(-$days)
	Write-Info "    Today is $Now and days must keep are $days. We will delete the files older than $LastWrite"
	#----- get files based on lastwrite filter in the specified folder ---#
	#----- Remove the write-host line from the below code if you want to schedule it using SQL Agent Job ---#
    	$Files = (Get-ChildItem -Path $targetpath -Recurse -Force | Where {$_.LastWriteTime -le "$LastWrite"})
	$NumFiles = $Files.Count
	Write-Info "    $NumFiles files will be deleted."
	foreach ($File in $Files) {
		if ($File -ne $NULL) {
			Write-Info "    Deleting File $File"
			Remove-Item $File.FullName | out-null
		    	Write-Info "    Deleted File $File"
		}
		else {
			Write-Info "    No files to delete!"
        	}
    	}
	Set-Location $PSScriptRoot
}

function Move-Backups() {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string]$targetpath
	)
    	$tempPath = $global:config.Temp_Backup
    	$Extension = $global:config.ExtensionBackup
	$user = $global:config.User
	$pass = $global:config.Pass

	$notLog = net use $targetpath /user:$user "$pass"

	$notLog = Robocopy "$tempPath\" "$targetpath\" "*.$Extension" /MOV /NJH /NJS /NFL /NDL

	$notLog = net use /delete $targetpath
}

function BackupAllUserDBsFromLocalServer(){
	[CmdletBinding()]
	Param (
	[Parameter(Mandatory=$true, Position=0)]
		[string]$targetpath
	)
	
	$tempPath = $global:config.Temp_Backup
	$Extension = $global:config.ExtensionBackup
	$SQLServer = $global:config.SqlServer
	$DBToBackup = $global:config.DBsToBackup
	
	foreach ($database in (Get-DbaDatabase -SqlInstance $SQLServer -Database $DBToBackup)) {
		$date = Get-Date -format "yyyyMMddHHmmss"
		$dbName = $database.Name
		$fileBackupName = "$dbName-$date.$Extension"
		Write-Info "#### Start Backup $dbName into $tempPath\$fileBackupName"
		Backup-SqlDatabase -ServerInstance $SQLServer -Database $dbName -BackupFile "$tempPath\$fileBackupName"
		Write-Info "#### Finish Backup $dbName"
		Write-Info "#### Start moving $dbName to $targetpath"
		Move-Backups $targetpath
		Write-Info "#### Finish moving $dbName"
	}
}

function DeleteOldAndBackupDB{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string]$targetpath,
		[Parameter(Mandatory=$true, Position=1)]
		[int]$days,
		[Parameter(Mandatory=$true, Position=2)]
		[string]$Extension
	)

	Write-Info "### Start backup all DBs"
	BackupAllUserDBsFromLocalServer $targetpath
	Write-Info "### Finished backup all DBs"
	Write-Info "### Start deleting old DBs on $targetpath"
	DeleteOld $targetpath $days $Extension
	Write-Info "### Finished deleting old DBs"
}
#endregion

#region: Teams functions
function Send-TeamsMessage() {
	[CmdletBinding()]
	Param 
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$uri,
		[Parameter(Mandatory=$true, Position=1)]
		[string]$isOk = "Error",
		[Parameter(Mandatory=$true, Position=2)]
		[string]$summaryText,
		[Parameter(Mandatory=$true, Position=3)]
		[string]$proxy
	)

	try {
		$Body = Get-Body $isOk $summaryText

		Invoke-RestMethod -uri $uri -Method Post -body $Body -ContentType 'application/json' -Proxy $proxy
	}
	catch {
		Write-Err $_
	}
}

function Get-Body {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, Position=0)]
		[string]$isOk = "Error",
		[Parameter(Mandatory=$true, Position=1)]
		[string]$summaryText
	)
	Begin {
		$BodyOut = ""
	}
    	Process {    
		$Title = "SVR-SQL SQL"
		#region: Load icon
		$Ico = $config.icon_ok
		$Summary = "$Title Backup $summaryText OK"
		$ThemeColor = "0072C6"

		if($isOk -ne "Ok")
		{
		    $Ico = $config.icon_fail
		$Summary = "$Title Backup $summaryText Error"
			$ThemeColor = "8E192E"
		}	
		#endregion

		#region: Body
		$BodyOut = @"
		{
			"@context": "https://schema.org/extensions",
			"@type": "MessageCard",
			"themeColor": "$ThemeColor",
			"summary": "$Summary",
			"title": "$Title",
			"sections": [{
				"activity": "**SQL BACKUP**",
				"image": "$Ico",
				"text": "$Summary"
			}]
		}
"@
        	#endregion	
	}	
	End {
		$BodyOut
	}
}
#endregion

function Clean-OldLogging() {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string]$logPath,
		[Parameter(Mandatory=$true, Position=1)]
		[int]$days
	)
	Write-Info "## Start delete old log files"
	Set-Location $logPath\
	$Now = Get-Date
	$LastWrite = $Now.AddDays(-$days)
	#----- get files based on lastwrite filter in the specified folder ---#
	#----- Remove the write-host line from the below code if you want to schedule it using SQL Agent Job ---#
	$Files = (Get-ChildItem -Path $logPath -Recurse -Force | Where {$_.LastWriteTime -le "$LastWrite"})
	foreach ($File in $Files) {
		if ($File -ne $NULL) {
			Write-Info "   Deleting File $File"
			Remove-Item $File.FullName | out-null
			Write-Info "   Deleted File $File"
		}
		else {
			Write-Info "   No files to delete!"
		}
	}
	Set-Location $PSScriptRoot
	Write-Info "## Finished delete old log files"
}

#region Logging
if($global:config.Debug_Log) {
	Start-Logging $global:log
}
Clean-OldLogging $global:config.Path_Log $global:config.DaysKeepLogFiles
#endregion

Write-Info "## Process backup $type starts"
$BackupState = "Ok"
try {
	switch ($type){
		"Friday" { DeleteOldAndBackupDB $config.Backup_Path_Friday $config.DaysKeepBackupFriday $config.ExtensionBackup }
		"Week" { DeleteOldAndBackupDB $config.Backup_Path_Dairly $config.DaysKeepBackupDairly $config.ExtensionBackup }
		"Historical" { DeleteOldAndBackupDB $config.Backup_Path_Historic $config.DaysKeepBackupHistoric $config.ExtensionBackup }
	}
}
catch {
	$BackupState = "Error"
	Write-Err $_
}

Write-Info "## End process backup $type"
$Webhook = $config.Webhook
Write-Info "## Teams message start to Webhook = $Webhook"
try {
	Send-TeamsMessage $config.Webhook $BackupState $type $config.proxy
	Write-Info "   Teams message sended"
}
catch {
	Write-Err $_
}
Write-Info "## End Teams message"
