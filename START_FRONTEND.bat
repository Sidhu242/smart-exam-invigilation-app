@echo off
REM Smart Exam Invigilation - Frontend Startup Script
REM This script starts the Flutter application

echo.
echo ========================================
echo Smart Exam Frontend - Starting...
echo ========================================
echo.

cd frontend

echo Checking if packages exist...
if not exist ".dart_tool" (
    echo Getting dependencies...
    call flutter pub get
    if errorlevel 1 (
        echo ERROR: flutter pub get failed
        pause
        exit /b 1
    )
)

echo.
echo Available devices:
call flutter devices
echo.

set /p device_choice="Select device or press Enter for default: "

if "%device_choice%"=="" (
    echo Starting Flutter app...
    call flutter run
) else (
    echo Starting Flutter app on selected device...
    call flutter run -d %device_choice%
)

pause
