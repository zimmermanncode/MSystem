@echo off
REM MSystem \\ CMD Shell integration for MSYS2
REM
REM Copyright (C) 2015-2016 Stefan Zimmermann <zimmermann.code@gmail.com>
REM
REM Licensed under the Apache License, Version 2.0

setlocal EnableExtensions || exit /b

if "%~1" == "/?" (
    echo Activates an MSYS2 environment inside a CMD shell,
    echo either in MSYS or MINGW32 or MINGW64 mode,
    echo by prepending the according MSYS2 bin\ paths to %%PATH%%.
    echo.
    echo MSYSTEM [/S] [MSYS ^| MINGW32 ^| MINGW64] [/W ^| /-W]]
    echo.
    echo   /S   Combine MINGW32 or MINGW64 with MSYS mode and its bin\ paths.
    echo   /W   Force opening a new CMD window.
    echo   /-W  Explicitly avoid opening a new CMD window.
    echo.
    echo In MSYS mode, MSystem's msys\ sub-directory with wrapper scripts
    echo BASH, PACMAN, MAKEPKG, and MAKEPKG-MINGW
    echo is also prepended to %%PATH%%.
    echo Call any of those scripts with /? for details after activation.
    echo.
    echo In MINGW modes, MSystem's mingw32\ or mingw64\ path
    echo with MINGW mode BASH wrapper scripts is prepended to %%PATH%%.
    echo Call BASH /? for details after activation.
    echo With given /S, the additional wrapper scripts of MSYS mode
    echo will also be available.
    echo.
    echo To work properly, either MSystem must be installed
    echo as a direct sub-directory of the MSYS2 installation,
    echo or the root directory of the MSYS2 installation
    echo ^(usually C:\path\to\msys32 or ...\msys64^)
    echo must be defined via %%MSYS2_ROOT%% or must be in %%PATH%%.
    echo.
    echo After successful activation,
    echo the environment name will be stored in %%MSYS2_SYSTEM%%
    echo and an according ^<MSYS^> or ^<MINGW32^> or ^<MINGW64^> tag
    echo ^(or ^<MINGW32^|MSYS^> or ^<MINGW64^|MSYS^> if activated with /S^)
    echo will be prepended to %%PROMPT%%.
    echo.
    echo If MSYSTEM is called from a non-interactive CMD instance
    echo ^(from another shell or graphical interface^),
    echo MSYSTEM will automatically start a new CMD window.
    echo You can also force a new window with /W
    echo and explicitly avoid a new window with /-W.
    echo
    echo Call MSYSTEM without an argument
    echo to show the currently active MSYS2 environment.
    echo.
    echo Call MSYSTEM /D to deactivate an MSYS2 environment.
    echo.
    echo Be careful when using MSYSTEM together with other shell environments
    echo ^(like virtual Python environments, etc...^).
    echo Due to %%PATH%% changes,
    echo the precedence of commands with same names also changes.
    echo Future versions of MSYSTEM will try to automatically avoid conflicts
    echo with certain other environment types.
    echo.
    echo Call MSYSTEM /X with any of the following specifiers
    echo to install MSYS2 features into other CMD shell extensions.
    echo.
    echo Install CLINK auto-completion for MSYSTEM and PACMAN with:
    echo.
    echo     MSYSTEM /X CLINK [clink settings directory]
    echo.
    echo If no CLINK settings directory is given,
    echo MSYSTEM will try to automatically find it.
    exit /b 0
)

REM --------------------------------------------------------------------------
REM No args

if "%~1" == "" (
    REM only show info and exit
    if "%MSYS2_SYSTEM%" == "" (
        echo No active MSYS2 environment.
        exit /b 1
    )
    echo %MSYS2_SYSTEM%
    exit /b 0
)

REM --------------------------------------------------------------------------
REM Handle install flag

if /i "%~1" == "/X" (
    REM install MSYS2 features into other CMD shell extensions
    shift /1
    endlocal
    goto :install
)
if /i "%~1" == "/I" (
    echo The /I flag is deprecated. Please use MSYSTEM /X in the future.
    shift /1
    endlocal
    goto :install
)

endlocal

REM ==========================================================================
REM Environment management

setlocal EnableExtensions EnableDelayedExpansion || exit /b

REM --------------------------------------------------------------------------
REM Handle environment deactivation flag

if /i "%~1" == "/D" (
    set MSYS2_SYSTEM=
    goto :deactivate
)

REM --------------------------------------------------------------------------
REM Parse arguments in a loop

REM default options
set newWindow=auto
set MSYS=false

:parseArgs

if /i "%~1" == "/W" (
    set newWindow=true
    shift /1
    goto :parseArgs
)

if /i "%~1" == "/-W" (
    set newWindow=false
    shift /1
    goto :parseArgs
)

if /i "%~1" == "/S" (
    set MSYS=true
    shift /1
    goto :parseArgs
)

REM Check for valid MSYS2 environment name and set %MSYS2_SYSTEM% accordingly
for %%M in (MSYS MINGW32 MINGW64) do if /i "%~1" == "%%M" (
    set MSYS2_SYSTEM=%%M
    shift /1
    goto :parseArgs
)

for %%F in (/X /I) do if /i "%~1" == "%%F" (
    echo MSYSTEM\\ERROR: %%F can only be used as first argument.
    echo Call MSYSTEM /? for help.
    exit /b 1
)

if not "%~1" == "" (
    echo MSYSTEM\\ERROR: Invalid argument '%~1'.
    echo Call MSYSTEM /? for help.
    exit /b 1
)

REM --------------------------------------------------------------------------
REM Handle request or need for new CMD window
:window

if %newWindow% == auto (
    REM check if started in non-interactive CMD process (via cmd /c ...)
    set "_cmdcmdline=!cmdcmdline!"
    if /i not "!_cmdcmdline: /c =!" == "!cmdcmdline!" (
        echo MSYSTEM: Detected non-interactive CMD shell!
        set newWindow=true
    )
)
if %newWindow% == true (
    echo MSYSTEM: Starting MSystem in new CMD shell window...
    start cmd /k cmd /k "%~f0" %* /-w
    exit /b
)

REM --------------------------------------------------------------------------
REM Check system and create variables for MSYS2 (de)activation
:prepare

if not "%MSYS2_ROOT%" == "" (
    goto :customRoot
)

REM try to find MSYS2 root directory in %PATH%
for %%S in (msys2_shell.cmd) do (
    set "MSYS2_ROOT=%%~dp$PATH:S"
    if not "!MSYS2_ROOT!" == "" (
        goto :checkRoot
    )
)

REM still no %MSYS2_ROOT% ==> assume that this script is in <MSYS2 root>\cmd\
set "cmdRoot=%~dp0"
REM remove trailing \ and cmd subdir
for %%D in ("%cmdRoot:~0,-1%") do (
    REM will not be exported on endlocal
    set "MSYS2_ROOT=%%~dpD"
)

:checkRoot

REM remove trailing \
set "MSYS2_ROOT=%MSYS2_ROOT:~0,-1%"
if not exist "%MSYS2_ROOT%\msys2_shell.cmd" (
    echo This script is not properly installed.
    echo Should be in ^<MSYS2 root^>\cmd\
    exit /b 1
)
goto :deactivate

:customRoot

if not exist "%MSYS2_ROOT%\" (
    set "error=does not exist or is not a directory"
    echo MSYSTEM\\ERROR: %%MSYS2_ROOT%% '%MSYS2_ROOT%' !error!.
    exit /b 1
)

REM --------------------------------------------------------------------------
REM Always deactivate current MSYS2 environment before activating a new one
:deactivate

REM remove any existing MSYS2 and MINGW32/64 bin paths from %PATH%
if not "%MSYS2_PATH%" == "" (
    call set "PATH=%%PATH:%MSYS2_PATH%;=%%"
)
if not "%MSYS2_MINGW32_PATH%" == "" (
    call set "PATH=%%PATH:%MSYS2_MINGW32_PATH%;=%%"
)
if not "%MSYS2_MINGW64_PATH%" == "" (
    call set "PATH=%%PATH:%MSYS2_MINGW64_PATH%;=%%"
)
REM and also remove any extra MSYS/MINGW tool wrapper scripts paths
call set "PATH=%%PATH:%~dp0msys;=%%"
call set "PATH=%%PATH:%~dp0mingw32;=%%"
call set "PATH=%%PATH:%~dp0mingw64;=%%"

REM remove any <MSYS> or <MINGW32/64> tags from %PROMPT%
REM (use temporary %_cleanPrompt% to avoid too many %PROMPT% changes,
REM  which can result in strange shell behavior)
set "_cleanPrompt=%PROMPT:$LMSYS$G$S=%"
set "_cleanPrompt=%_cleanPrompt:$LMINGW32$G$S=%"
set "_cleanPrompt=%_cleanPrompt:$LMINGW32|MSYS$G$S=%"
set "_cleanPrompt=%_cleanPrompt:$LMINGW64$G$S=%"
set "_cleanPrompt=%_cleanPrompt:$LMINGW64|MSYS$G$S=%"

REM check if only deactivation requested (via MSYSTEM /D)
if "%MSYS2_SYSTEM%" == "" (
    set "_prompt=%_cleanPrompt%"

    set MSYS2_PATH=
    set MSYS2_MINGW32_PATH=
    set MSYS2_MINGW64_PATH=

    goto :end
)

REM --------------------------------------------------------------------------
:activate

REM construct MSYS2 and MINGW32/64 bin paths
set "MSYS2_PATH=%MSYS2_ROOT%\usr\local\bin;%MSYS2_ROOT%\usr\bin;%MSYS2_ROOT%\bin"
set "MSYS2_MINGW32_PATH=%MSYS2_ROOT%\mingw32\bin"
set "MSYS2_MINGW64_PATH=%MSYS2_ROOT%\mingw64\bin"

REM the <tag> to be prepended to prompt
set "promptTag=%MSYS2_SYSTEM%"

REM prepend MSYS2 bin paths and/or MINGW32/64 bin paths to %PATH%
:setPath

if "%MSYS2_SYSTEM%" == "MSYS" (
    REM also prepend the extra MSYS tool wrapper scripts path
    set "PATH=%~dp0msys;%MSYS2_PATH%;%PATH%"
    goto :setPrompt
)

REM MINGW32/64
if %MSYS% == true (
    REM first prepend MSYS bin and extra scripts paths
    set "PATH=%~dp0msys;%MSYS2_PATH%;%PATH%"
    REM and add |MSYS to the prompt tag
    set "promptTag=%promptTag%|MSYS"
)
if "%MSYS2_SYSTEM%" == "MINGW32" (
    REM prepend MINGW32 bin and extra scripts paths
    set "PATH=%~dp0mingw32;%MSYS2_MINGW32_PATH%;%PATH%"
)
if "%MSYS2_SYSTEM%" == "MINGW64" (
    REM prepend MINGW64 bin and extra scripts paths
    set "PATH=%~dp0mingw64;%MSYS2_MINGW64_PATH%;%PATH%"
)

REM prepend the appropriate <MSYS> or <MINGW32/64> tag to prompt
:setPrompt

set "_prompt=$L%promptTag%$G$S%_cleanPrompt%"

REM --------------------------------------------------------------------------
REM Successfully finished MSYS2 environment (de)activation
:end

REM export new environment variables
endlocal && set "MSYS2_SYSTEM=%MSYS2_SYSTEM%" ^
         && set "MSYS2_PATH=%MSYS2_PATH%" ^
         && set "MSYS2_MINGW32_PATH=%MSYS2_MINGW32_PATH%" ^
         && set "MSYS2_MINGW64_PATH=%MSYS2_MINGW64_PATH%" ^
         && set "PATH=%PATH%" ^
         && set "PROMPT=%_prompt%"
exit /b 0


REM ==========================================================================
REM Install MSYS2 features into other CMD shell extensions
:install

if "%~1" == "" (
    echo Missing CMD shell extension specifier.
    echo Call MSYSTEM /? for help.
    exit /b 1
)
if /i "%~1" == "clink" (
   shift /1
   goto :clink
)

REM --------------------------------------------------------------------------
REM Install MSYS2 auto-completion features into CLINK
:clink

setlocal EnableDelayedExpansion

if "%~1" == "" (
    REM no clink settings dir given ==> try to find
    set "clinkDir=%LOCALAPPDATA%\clink"
    if not exist "!clinkDir!\" (
        echo Could not find CLINK settings directory.
        echo Please provide it as additional argument.
        exit /b 1
    )
) else (
    if not exist "%~1\" (
        echo '%~3' does not exist or is not a directory.
        exit /b 1
    )
    set "clinkDir=%~1"
)

set nl=^


set "root=%~dp0"
REM remove trailing \
set "root=%root:~0,-1%"
REM create a LUA script that loads all auto-completion scripts from .\clink\
set msysLua=                                                             !nl!^
    local root = "%root:\=\\%"                                           !nl!^
    local scripts = {}                                                   !nl!^
    local p = io.popen("dir /b " .. root .. "\\clink\\*.lua")            !nl!^
    for file in p:lines() do                                             !nl!^
        table.insert(scripts, file)                                      !nl!^
    end                                                                  !nl!^
    if p:close() then                                                    !nl!^
       for _, file in next, scripts do                                   !nl!^
           dofile(root .. "\\clink\\" .. file)                           !nl!^
       end                                                               !nl!^
    end                                                                  !nl!^


echo Writing '%clinkDir%\msys2.lua'
echo !msysLua! > %clinkDir%\msys2.lua

endlocal
exit /b 0
