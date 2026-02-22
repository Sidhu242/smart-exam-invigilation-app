@echo off
REM Smart Exam Invigilation - Backend Startup Script
REM This script starts the Node.js backend server

echo.
echo ========================================
echo Smart Exam Backend - Starting...
echo ========================================
echo.

cd backend-nodejs

echo Checking if node_modules exists...
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo ERROR: npm install failed
        pause
        exit /b 1
    )
)

echo.
echo Starting server in development mode...
echo Backend will run on: http://localhost:5000
echo API health check: http://localhost:5000/api/health
echo.
echo Press Ctrl+C to stop the server
echo.

call npm run dev

pause
