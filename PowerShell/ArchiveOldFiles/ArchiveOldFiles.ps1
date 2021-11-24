[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$sourcePath,
	[Parameter(Mandatory=$true, Position=1)]
    [string]$archivePath
)

#region Get the config from our config file
$global:config = (Get-Content "$PSScriptRoot\config.json") -Join "`n" | ConvertFrom-Json
$pathlog = $global:config.Path_Log
$date = Get-Date -format "yyyyMMdd-HHmmss"
$fileName = "$date.log"
$global:log = "$pathlog\$fileName"
#endregion

#region Import functions
Import-Module "$PSScriptRoot\Helpers\Log.psm1"
#endregion

#region Archive
function GetFileLogName {
    Begin {
        $fileLogName = ""
    }
    Process {
        $date = Get-Date -format "yyyyMMdd-HHmmss"
	    $fileName = "$date.log"
	    $path = $config.Path_MovLog
        $fileLogName = "$path\$fileName"
    }
    End {
        $fileLogName
    }
}

function MoveFiles(){
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string]$sourcePath,
		[Parameter(Mandatory=$true, Position=1)]
        [string]$archivePath
	)
    $pathFile = GetFileLogName
    
    $MinDayWriting = [datetime]::ParseExact($config.LastWritenDateToDelete, 'dd/mm/yyyy', $NULL).ToString('yyyymmdd') 
    $MinDayCreted = [datetime]::ParseExact($config.LastCreateDateToDelete, 'dd/mm/yyyy', $NULL).ToString('yyyymmdd') 

    Robocopy $sourcePath $archivePath /s /MOVE /MINAGE:$MinDayWriting /MINLAD:$MinDayCreted /LOG:"$pathFile"
}
#endregion

#region Logging
if($global:config.Debug_Log) {
	Start-Logging $global:log
}
Remove-OldLogFiles $config.Path_Log $config.DaysKeepLogFiles
#endregion

Write-Info "## Proces Move old files starts"
MoveFiles $sourcePath $archivePath
Write-Info "## End proces"
