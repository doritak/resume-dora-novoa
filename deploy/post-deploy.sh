#!/bin/bash
set -e

# ===========================================
# Post-Deployment Script
# ===========================================
# Run this after App Runner service is created
# to upload static files and run migrations

# Configuration - CHANGE THESE VALUES
AWS_REGION="us-east-1"
S3_BUCKET_NAME="resume-dora-novoa-static"

# Load environment variables
export $(cat .env.prod | xargs)

echo "=== Uploading Static Files to S3 ==="
python manage.py collectstatic --noinput

echo "=== Running Database Migrations ==="
python manage.py migrate --noinput

echo "=== Creating Superuser (if needed) ==="
echo "Run: python manage.py createsuperuser"

echo ""
echo "=== Post-deployment Complete ==="
