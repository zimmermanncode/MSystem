@echo off
REM MSystem \\ CMD Shell integration for MSYS2
REM
REM Copyright (C) 2015-2016 Stefan Zimmermann <zimmermann.code@gmail.com>
REM
REM Licensed under the Apache License, Version 2.0

setlocal EnableExtensions || exit /b

if "%~1" == "/?" (
    echo Runs MSYS2 bash.exe in MINGW64 mode.
    echo.
    echo BASH [args ...]
    echo.
    echo First starts a non-interactive bash.exe with --login flag,
    echo which then switches to current working directory
    echo and runs a new bash.exe instance with the given arguments.
    echo.
    echo If no arguments are given, a new shell window will be started.
    echo Call BASH -i to run an interactive bash.exe in current shell window.
    exit /b 0
)
endlocal

setlocal EnableExtensions EnableDelayedExpansion || exit /b

if not "%MSYS2_MINGW32_PATH%" == "" (
    call set "PATH=%%PATH:%MSYS2_MINGW32_PATH%;=%%"
)
REM and also remove any extra MSYS/MINGW tool wrapper scripts paths
for %%R in ("%~dp0..") do (
    call set "PATH=!!PATH:%%~fR\msys;=!!"
    call set "PATH=!!PATH:%%~fR\mingw32;=!!"
    call set "PATH=!!PATH:%%~fR\mingw64;=!!"
)

set MSYSTEM=MINGW64
if "%~1" == "" (
    start bash.exe --login -c 'cd "%cd%" ^&^& bash'
) else (
    bash.exe --login -c 'cd "%cd%" ^&^& bash %*'
)

endlocal
