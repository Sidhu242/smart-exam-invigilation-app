@echo off
REM Smart Exam Invigilation - Complete Setup Script
REM Runs all first-time setup steps

echo.
echo ========================================
echo Smart Exam Invigilation System
echo Complete Setup Script
echo ========================================
echo.

REM Check if Node.js is installed
echo Checking for Node.js...
call node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
echo ✓ Node.js found

REM Check if Flutter is installed
echo Checking for Flutter...
call flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/
    pause
    exit /b 1
)
echo ✓ Flutter found

REM Check if MySQL is running
echo Checking for MySQL...
call tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I /N "mysqld.exe">NUL
if errorlevel 1 (
    echo WARNING: MySQL doesn't appear to be running
    echo Please start MySQL before continuing
    echo.
    set /p continue="Continue anyway? (y/n): "
    if not "%continue%"=="y" (
        exit /b 1
    )
)
echo ✓ MySQL appears to be running

REM Setup Backend
echo.
echo ========================================
echo Setting up Backend...
echo ========================================
cd backend-nodejs

if not exist "node_modules" (
    echo Installing backend dependencies...
    call npm install
)

if not exist ".env" (
    echo Creating .env file from template...
    call copy .env.example .env
    echo NOTE: You need to update backend-nodejs\.env with your MySQL credentials
)

echo ✓ Backend setup complete

REM Setup Frontend
echo.
echo ========================================
echo Setting up Frontend...
echo ========================================
cd ..\frontend

if not exist ".dart_tool" (
    echo Installing frontend dependencies...
    call flutter pub get
)

echo ✓ Frontend setup complete

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Update backend-nodejs\.env with your MySQL credentials
echo 2. Run START_BACKEND.bat to start the backend server
echo 3. Run START_FRONTEND.bat to start the Flutter app
echo.
echo For detailed setup instructions, see COMPLETE_SETUP_GUIDE.md
echo.

pause
