@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
  echo Usage: chuyen file.html
  echo Example: chuyen SS_10.html
  echo
  echo File HTML phai nam trong thu muc Books.
  exit /b 1
)

set "file=%~1"
set "root=%~dp0"
set "source=%root%Books\%file%"
set "dest=%root%Navigation\temp.html"

if not exist "%source%" (
  echo Loi: File "%file%" khong ton tai trong thu muc Books.
  echo Cac file Books hien co:
  dir /b "%root%Books\*.html"
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%root%chuyen.ps1" "%file%"
if errorlevel 1 (
  exit /b 1
)
