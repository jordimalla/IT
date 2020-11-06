@echo off
:: add other test for the arguments here...
if not [%1]==[] goto main
else goto showMainHelp

:exit
exit /B 1

:showMainHelp
echo Use this correct form.
echo.
echo %0 param%%1 param%%2
echo       param%%1 [init, atack]
echo       param%%2 -h Help about the command
goto exit

:main
if [%1] == [init] (
    goto checkInit
) else if [%1] == [atack] (
    goto atack
) else (
    echo Incorrect arguments.
    echo.
    goto showMainHelp
)
echo do something with all arguments (%%* == %*) here...
goto exit

:showInitHelp
echo Help for Init.
echo.
echo %0 init param%%2
echo    param%%2 a number of directories to create
echo    param%%3 a number of files into each directories
goto exit

:checkInit
if [%2] == [-h] (
    goto showInitHelp
) else if %2 EQU +%2 (
    if %3 EQU +%3 (
        goto initCreate
    )
) else (
    goto initErrorComands
)
goto exit

:initErrorComands
    echo Incorrect arguments.
    echo.
    goto showInitHelp
goto exit

:initCreate
setlocal
set /A num_dir=%2
set /A num_files=%3
for /L %%i IN (0,1,%num_dir%) DO (
    mkdir Directory_0%%i
    cd Directory_0%%i
    for /L %%e IN (0,1,%num_files%) DO (
        echo Text of test file. > File_%%e.txt
    )
    cd ..
)
endlocal
goto exit

:atack
for /R . %%G IN (*.txt) DO (
    move %%G %%G.encrypted
)
goto exit
