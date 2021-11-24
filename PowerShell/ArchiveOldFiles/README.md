# ArchiveOldFiles
## Description
This Powershell function allow us to archive those files which have been created before a concrete date [LastCreateDateToDelete] and it hasn't been 
modified after an other concrete date [LastWritenDateToDelete]

### Config.json
Debug_Log: If it is true, debug logs are stored
Path_Log: Location of function logs
LastWritenDateToDelete: Date in format "dd/mm/yyyy"
LastCreateDateToDelete: Date in format "dd/mm/yyyy"
DaysKeepLogFiles: Integer indicating the maximum number of log files stored
Path_MovLog: Location of Robocopy output file
