#region Get the config from our config file
$global:config = (Get-Content "$PSScriptRoot\..\config.json") -Join "`n" | ConvertFrom-Json
#endregion

function Remove-OldLogFiles() {
    $logPath = $global:config.Path_Log
    $days = $global:config.DaysKeepLogFiles

	Write-Info "## Start delete old log files"
	Set-Location $logPath\
	$Now = Get-Date
	$LastWrite = $Now.AddDays(-$days)

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

# This function logs messages with a type tag
function Write-LogMessage() {
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$tag,
		[Parameter(Mandatory=$true, Position=1)]
        	[string]$message
	)
	if($global:config.Debug_Log)
	{
		Write-Host ("[{0}] - {1} - {2}" -f $tag, (Get-Date), $message)
	}
}

#region: Logging functions
function Start-Logging() {
[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$logFile
	)
	if($global:config.Debug_Log)
	{
		$date = Get-Date -format "yyyyMMdd-HHmmss"
	    $fileName = "$date.log"
		$path = $global:config.Path_Log
	    $pathFile = "$path\$fileName"

		try {
			Start-Transcript -path $logFile -force -append 
			Write-Info "Transcript is being logged to $pathFile"
		} catch [Exception] {
			 Write-Err "Transcript is already being logged to $pathFile"
		}
	}
}

function Write-Info() {
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
        	[string]$message
	)
	
	Write-LogMessage -Tag "Info" -Message $message
}

function Write-Err() {
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
        	[string]$message
	)

	Write-LogMessage -Tag "Error" -Message $message
}
#endregion
