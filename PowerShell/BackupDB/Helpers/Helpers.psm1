#region Get the config from our config file
$global:config = (Get-Content "$PSScriptRoot\..\config\vsn.json") -Join "`n" | ConvertFrom-Json
#endregion

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
