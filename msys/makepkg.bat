@echo off
REM MSystem | CMD shell integration for MSYS2
REM
REM Copyright (C) 2015-2016 Stefan Zimmermann <zimmermann.code@gmail.com>
REM
REM Licensed under the Apache License, Version 2.0

setlocal EnableExtensions || exit /b

if "%~1" == "/?" (
    echo Runs MSYS2 'makepkg' script via bash.exe
    echo.
    echo MAKEPKG [args ...]
    echo.
    echo First starts a non-interactive bash.exe with --login flag,
    echo which then switches to current working directory
    echo and runs 'makepkg' with the given arguments.
    exit /b 0
)

"%~dp0bash.bat" -c "makepkg %*"

endlocal
