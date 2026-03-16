@echo off

REM MediFlow Pro Backend Deployment Script for Windows
REM This script automates the backend deployment process

echo 🚀 Starting MediFlow Pro Backend Deployment...

echo.
echo 1. Checking dependencies...
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found. Please install Python 3.10+
    exit /b 1
)

where pip >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ pip not found. Please install pip
    exit /b 1
)
echo ✅ Python and pip found

echo.
echo 2. Installing dependencies...
cd /d "C:\Users\yakshith\Desktop\mediflow_pro\backend"
pip install -r requirements.txt

if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    exit /b 1
)
echo ✅ Dependencies installed successfully

echo.
echo 3. Setting up database columns for Google Sign-In...
python add_google_columns.py

if %errorlevel% neq 0 (
    echo ❌ Failed to add Google Sign-In columns
    exit /b 1
)

echo.
echo 4. Making password_hash column nullable for Google users...
python make_password_hash_nullable.py

if %errorlevel% neq 0 (
    echo ❌ Failed to make password_hash nullable
    exit /b 1
)
echo ✅ Database schema updated for Google Sign-In

echo.
echo 5. Verifying environment configuration...
if not exist ".env" (
    echo ⚠️  .env file not found. Creating from .env.example
    copy .env.example .env
    echo    Please edit .env to configure your database and other settings
) else (
    echo ✅ .env file found
)

echo.
echo 6. Testing backend endpoints...
python test_auth_endpoints.py

if %errorlevel% equ 0 (
    echo ✅ Backend endpoints verified successfully
) else (
    echo ⚠️  Some endpoint tests failed. Check logs above.
)

echo.
echo 🎉 Deployment completed!
echo.
echo To start the backend:
echo cd C:\Users\yakshith\Desktop\mediflow_pro\backend
echo python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
echo.
echo For Android emulator, use URL: http://10.0.2.2:8001/api
