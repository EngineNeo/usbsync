@echo off

rem Read the source and destination directories from the "directories.txt" file
set /p "source="<"windirectories.txt"
set /p "destination="<"windirectories.txt"

echo Synchronization process is starting...

rem Get the timestamp from the source
set /p sourcetimestamp=<"%source%\timestamp"
echo Source timestamp is %sourcetimestamp%

rem Get the timestamp of the most recently modified file in the destination
for /f "delims=" %%a in ('powershell -Command "Get-ChildItem -Path '%destination%' -Recurse | Where-Object {!$_.PSIsContainer} | Sort-Object LastWriteTime -Descending | Select-Object -First 1 LastWriteTime | ForEach-Object {$_.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ssZ')}"') do set "destinationtimestamp=%%a"
echo Destination timestamp is: %destinationtimestamp%

echo Comparing timestamps...

@echo off

echo Comparing timestamps...

rem Compare the timestamps and do the synchronization
if "%destinationtimestamp%" gtr "%sourcetimestamp%" (
    echo Destination is newer. Updating source directory...
    robocopy "%destination%" "%source%" /MIR

    echo Updating timestamp in source directory...

    rem Use the most recent file timestamp to mark the changes
    echo %destinationtimestamp% > "%source%\timestamp"
) else if "%destinationtimestamp%" equ "%sourcetimestamp%" (
    echo Everything is up to date.
    exit /b 0
) else (
    echo Source is newer. Updating destination directory...
    robocopy "%source%" "%destination%" /MIR /XF timestamp
)

echo Synchronization process complete.

pause
