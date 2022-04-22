::USAGE
::  ospctl [-v] [-d DIR] CMD
::
::OPTIONS
::  DIR is the directory to specify another location for Open Server.
::
::  CMD is one of the commands explained below.
::
::  These commands are used to control the Open Server main process:
::    run         Launch the Open Server
::    kill        Terminate the Open Server
::    force-kill  Terminate the Open Server forcefully
::
::  These commands are used to control servers:
::    start       Start servers
::    stop        Stop servers
::    restart     Restart servers
::
::  Other commands
::    status      Show status for all processes
::
::ENVIRONMENT
::  OSP_HOME
::  If specified and valid, it's used as the Open Server home directory.
::  It can be overwritten with the "-d" option in the command line.

@echo off

if "%~1" == "" goto :print_usage

setlocal

set "OSP_NAME=Open Server.exe"

set "OSP_VERBOSE="
if /i "%~1" == "-v" (
	set "OSP_VERBOSE=1"
	shift /1
)

if not defined OSP_HOME set "OSP_HOME=%~dp0"

if /i "%~1" == "-d" (
	set "OSP_HOME=%~2"
	shift /1
	shift /1
)

set "OSP_HOME=" & call :detect "%OSP_HOME%"

if not defined OSP_HOME (
	call :warn "%OSP_NAME% not found"
	exit /b 1
)

for %%a in ( run kill force-kill status ) do if /i "%~1" == "%%~a" goto :%%~a

for %%a in ( start stop restart ) do if /i "%~1" == "%%~a" (
	call :load-ini
	call :send-command %%~a
	goto :EOF
)

call :warn "Illegal command: '%~1'"
exit /b 1

:: ========================================================================

:detect
for %%f in ( "%~1\." ) do (
	if defined OSP_VERBOSE call :warn "Try: %%~ff"
	if exist "%%~ff\%OSP_NAME%" (
		set "OSP_HOME=%%~ff"
	) else if not "%%~df\." == "%%~ff." (
		call %~0 "%%~ff\.."
	)
)
goto :EOF

:: ========================================================================

:run
start "%OSP_NAME% running..." /b "%OSP_HOME%\%OSP_NAME%"
goto :EOF

:: ========================================================================

:kill
taskkill /fi "IMAGENAME EQ %OSP_NAME%"
goto :EOF

:: ========================================================================

:force-kill
taskkill /f /fi "IMAGENAME EQ %OSP_NAME%"
goto :EOF

:: ========================================================================

:load-ini
for /f "usebackq tokens=1,* delims==" %%a in ( "%OSP_HOME%\userdata\init.ini" ) do (
	if /i "%%~a" == "web" set "OSP_INI_WEB=%%~b"
	if /i "%%~a" == "login" set "OSP_INI_USER=%%~b"
	if /i "%%~a" == "pass" set "OSP_INI_PASS=%%~b"
	if /i "%%~a" == "port" set "OSP_INI_PORT=%%~b"
)
goto :EOF

:: ========================================================================

:send-command
if %OSP_INI_WEB% neq 1 (
	call :warn "Web management not enabled"
	exit /b 1
)

echo:Sending command: '%~1'

"%OSP_HOME%\modules\wget\bin\wget.exe" --http-user="%OSP_INI_USER%" --http-passwd="%OSP_INI_PASS%" -q -O nul "http://127.0.0.1:%OSP_INI_PORT%/%~1"

goto :EOF

:: ========================================================================

:status
for %%f in ( powershell.exe wmic.exe ) do if not "%%~$PATH:f" == "" goto :status_%%~nf
call :warn "Unable to display status"
goto :EOF

:status_powershell
powershell -c "gwmi Win32_Process|?{$_.Caption -eq '%OSP_NAME%'}|%% {($p=$_.ProcessId),$_.CommandLine,''}; if(!$p){exit} gwmi Win32_Process|?{$_.ParentProcessId -eq $p}|%% {$_.ProcessId,$_.CommandLine,''}"
goto :EOF

:status_wmic
set "OSP_PID="

for /f "tokens=1,* delims==" %%a in ( '
	wmic Process where Caption^="%OSP_NAME%" get ProcessId^,CommandLine /value ^| findstr "."
' ) do (
	echo:%%~a=%%~b
	if /i "%%~a" == "ProcessId" set "OSP_PID=%%~b"
)

if not defined OSP_PID goto :EOF

echo:

wmic Process where ParentProcessId=%OSP_PID% get ProcessId,CommandLine /value
goto :EOF

:: ========================================================================

:warn
>&2 echo:%~1
goto :EOF

:: ========================================================================

:print_usage
for /f "tokens=1,* delims=:" %%a in ( 'findstr /n "." "%~f0"' ) do (
	if /i "%%~b" == "@echo off" goto :EOF
	echo:%%~b
)
goto :EOF

:: ========================================================================

:: EOF
