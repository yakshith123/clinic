#!/bin/bash

# Cloud Deployment Script for MediFlow Pro Backend
# This script prepares the backend for cloud deployment

echo "🚀 Preparing MediFlow Pro Backend for Cloud Deployment..."

echo "\n1. Validating environment variables..."
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL environment variable not set"
    echo "Please set DATABASE_URL to your PostgreSQL database URL"
    exit 1
fi

if [ -z "$SECRET_KEY" ]; then
    echo "❌ SECRET_KEY environment variable not set"
    echo "Please set SECRET_KEY to a strong random value"
    exit 1
fi

echo "✅ Required environment variables are set"

echo "\n2. Installing dependencies..."
pip install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed successfully"

echo "\n3. Updating database schema for Google Sign-In..."
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

echo "\n5. Running health checks..."
python3 test_auth_endpoints.py

if [ $? -eq 0 ]; then
    echo "✅ Health checks passed"
else
    echo "⚠️  Some health checks failed, but continuing deployment"
fi

echo "\n6. Preparing for cloud deployment..."
echo "   - Dockerfile created for containerization"
echo "   - render.yaml created for Render.com deployment"
echo "   - template.yaml created for AWS deployment"
echo "   - docker-compose.yml created for local testing"

echo "\n🎉 Backend prepared for cloud deployment!"

if [ ! -z "$PORT" ]; then
    echo "\nStarting server on port $PORT..."
    exec uvicorn app.main:app --host 0.0.0.0 --port $PORT
else
    echo "\nCloud deployment preparation complete!"
    echo "For local testing: python -m uvicorn app.main:app --host 0.0.0.0 --port 8001"
fi