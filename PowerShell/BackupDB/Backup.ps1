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
    Write-Info "Start delete old files"
    Set-Location $targetpath\
	$Now = Get-Date
	$LastWrite = $Now.AddDays(-$days)
	#----- get files based on lastwrite filter in the specified folder ---#
	#----- Remove the write-host line from the below code if you want to schedule it using SQL Agent Job ---#
	#$Files = Get-Childitem $targetpath -Include $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
    $Files = (Get-ChildItem -Path $targetpath -Recurse -Force | Where {$_.LastWriteTime -le "$LastWrite"})
	foreach ($File in $Files) {
		if ($File -ne $NULL) {
			Write-Info "Deleting File $File"
			Remove-Item $File.FullName | out-null
            Write-Info "Deleted File $File"
        }
		else {
			Write-Info "No files to delete!"
        }
    }
    Set-Location $PSScriptRoot
    Write-Info "Finished delete old files"
}

function Move-Backups() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
		[string]$targetpath
    )
    $tempPath = $global:config.Temp_Backup
    $Extension = $global:config.ExtensionBackup

    $notLog = net use $targetpath /user:localdomain\prevensalud "<En=T8"
	
    $notLog = Robocopy "$tempPath\" "$targetpath\" "*.$Extension" /MOV /NJH /NJS /NFL /NDL
    
    $notLog = net use /delete $targetpath
}

function BackupAllUserDBsFromLocalServer(){
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
		[string]$targetpath
    )
    #Set-Location SQLSERVER:\SQL\localhost\SQLEXPRESS\Databases  
    $date = Get-Date -format "yyyyMMddHHmmss"
    $tempPath = $global:config.Temp_Backup
    $Extension = $global:config.ExtensionBackup
    foreach ($database in (Get-ChildItem "SQLSERVER:\SQL\localhost\SQLEXPRESS\Databases")) {
        $dbName = $database.Name
        $fileBackupName = "$dbName-$date.$Extension"
        Write-Info "Start Backup $dbName"
        Backup-SqlDatabase -ServerInstance "localhost\SQLEXPRESS" -Database $dbName -BackupFile "$tempPath\$fileBackupName"
        Write-Info "Finish Backup $dbName"
        Write-Info "Start moving $dbName"
        Move-Backups $targetpath
        Write-Info "Finish moving $dbName"
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

    Write-Info "Start backup all DBs"
    BackupAllUserDBsFromLocalServer $targetpath
    Write-Info "Finished backup all DBs"
    Write-Info "Start deleting old DBs"
    DeleteOld $targetpath $days $Extension
    Write-Info "Finished deleting old DBs"
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
        [string]$summaryText
    )

    try {
        $Body = Get-Body $isOk $summaryText

        Invoke-RestMethod -uri $uri -Method Post -body $Body -ContentType 'application/json'
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
        $Title = "Prevensalud SQL"
	    #region: Load icon
	    $Ico = $config.icon_ok
        $Summary = "$Title Backup $summaryText OK"

	    if($isOk -ne "Ok")
	    {
		    $Ico = $config.icon_fail
            $Summary = "$Title Backup $summaryText Error"
	    }	
	    #endregion

	    #region: Body
	    $BodyOut = @"
	    {
            "themeColor": "0072C6",
            "summary": "$Summary",
            "text":"$Summary"
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
    Write-Info "Start delete old files"
    Set-Location $logPath\
	$Now = Get-Date
	$LastWrite = $Now.AddDays(-$days)
	#----- get files based on lastwrite filter in the specified folder ---#
	#----- Remove the write-host line from the below code if you want to schedule it using SQL Agent Job ---#
    $Files = (Get-ChildItem -Path $logPath -Recurse -Force | Where {$_.LastWriteTime -le "$LastWrite"})
	foreach ($File in $Files) {
		if ($File -ne $NULL) {
			Write-Info "Deleting File $File"
			Remove-Item $File.FullName | out-null
            Write-Info "Deleted File $File"
        }
		else {
			Write-Info "No files to delete!"
        }
    }
    Set-Location $PSScriptRoot
    Write-Info "Finished delete old files"
}

#region Logging
if($global:config.Debug_Log) {
	Start-Logging $global:log
}
Clean-OldLogging $global:config.Path_Log $global:config.DaysKeepLogFiles
#endregion

Write-Info "Process starts"
$BackupState = "Ok"
try {
    switch ($type){
        "Viernes" { DeleteOldAndBackupDB $config.Backup_Path_Friday $config.DaysKeepBackupFriday $config.ExtensionBackup }
        "Semanal" { DeleteOldAndBackupDB $config.Backup_Path_Dairly $config.DaysKeepBackupDairly $config.ExtensionBackup }
        "Historico" { DeleteOldAndBackupDB $config.Backup_Path_Historic $config.DaysKeepBackupHistoric $config.ExtensionBackup }
    }
}
catch {
   $BackupState = "Error"
    Write-Err $_
}

Write-Info "Teams message start"
try {
    Send-TeamsMessage $config.Webhook $BackupState $type
    Write-Info "Teams message sended"
}
catch {
    Write-Err $_
}
