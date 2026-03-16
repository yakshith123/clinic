#!/bin/bash

# MediFlow Pro Backend Deployment Script
# This script automates the backend deployment process

echo "🚀 Starting MediFlow Pro Backend Deployment..."

echo "\n1. Checking dependencies..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python 3.10+"
    exit 1
fi

if ! command -v pip &> /dev/null; then
    echo "❌ pip not found. Please install pip"
    exit 1
fi

echo "✅ Python3 and pip found"

echo "\n2. Installing dependencies..."
cd /Users/yakshith/Desktop/mediflow_pro/backend
pip install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed successfully"

echo "\n3. Setting up database columns for Google Sign-In..."
python3 add_google_columns.py

if [ $? -ne 0 ]; then
    echo "❌ Failed to add Google Sign-In columns"
    exit 1
fi

echo "\n4. Making password_hash column nullable for Google users..."
python3 make_password_hash_nullable.py

if [ $? -ne 0 ]; then
    echo "❌ Failed to make password_hash nullable"
    exit 1
fi

echo "✅ Database schema updated for Google Sign-In"

echo "\n5. Verifying environment configuration..."
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Creating from .env.example"
    cp .env.example .env
    echo "   Please edit .env to configure your database and other settings"
else
    echo "✅ .env file found"
fi

echo "\n6. Testing backend endpoints..."
python3 test_auth_endpoints.py

if [ $? -eq 0 ]; then
    echo "✅ Backend endpoints verified successfully"
else
    echo "⚠️  Some endpoint tests failed. Check logs above."
fi

echo "\n🎉 Deployment completed!"
echo "\nTo start the backend:" 
echo "cd /Users/yakshith/Desktop/mediflow_pro/backend"
echo "python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload"
echo "\nFor Android emulator, use URL: http://10.0.2.2:8001/api"
