set datetimef=%date:~-4%_%date:~3,2%_%date:~0,2%__%time:~0,2%_%time:~3,2%_%time:~6,2%

robocopy "source" "destination" /MOVE /E /COPYALL /V /NP /Z /R:10 /W:30 /LOG:G:\logo_%datetimef%.log
