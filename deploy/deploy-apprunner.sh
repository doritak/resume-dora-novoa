#!/bin/bash
set -e

# ===========================================
# AWS App Runner Deployment Script
# ===========================================
# Prerequisites:
#   - AWS CLI configured (aws configure)
#   - Docker installed and running
#   - jq installed (brew install jq)

# Configuration - CHANGE THESE VALUES
AWS_REGION="us-east-1"
APP_NAME="resume-dora-novoa"
ECR_REPO_NAME="resume-dora-novoa"
S3_BUCKET_NAME="resume-dora-novoa-static"
RDS_INSTANCE_ID="resume-dora-novoa-db"
RDS_DB_NAME="portfolio"
RDS_USERNAME="dbadmin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== AWS App Runner Deployment ===${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# ===========================================
# Step 1: Create ECR Repository
# ===========================================
echo -e "\n${YELLOW}Step 1: Creating ECR Repository...${NC}"
aws ecr create-repository \
    --repository-name $ECR_REPO_NAME \
    --region $AWS_REGION \
    2>/dev/null || echo "Repository already exists"

# ===========================================
# Step 2: Create S3 Bucket for Static Files
# ===========================================
echo -e "\n${YELLOW}Step 2: Creating S3 Bucket...${NC}"
aws s3 mb s3://$S3_BUCKET_NAME --region $AWS_REGION 2>/dev/null || echo "Bucket already exists"

# Configure bucket for public read (static files)
aws s3api put-public-access-block \
    --bucket $S3_BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Bucket policy for public read
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${S3_BUCKET_NAME}/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy file:///tmp/bucket-policy.json

# Enable CORS for S3
cat > /tmp/cors-config.json << EOF
{
    "CORSRules": [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET"],
            "AllowedOrigins": ["*"],
            "MaxAgeSeconds": 3000
        }
    ]
}
EOF

aws s3api put-bucket-cors --bucket $S3_BUCKET_NAME --cors-configuration file:///tmp/cors-config.json

echo -e "${GREEN}S3 bucket configured successfully${NC}"

# ===========================================
# Step 3: Create RDS PostgreSQL Instance
# ===========================================
echo -e "\n${YELLOW}Step 3: Creating RDS Instance...${NC}"
echo -e "${YELLOW}Enter a password for the database (min 8 characters):${NC}"
read -s RDS_PASSWORD

aws rds create-db-instance \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --db-instance-class db.t4g.micro \
    --engine postgres \
    --engine-version 16 \
    --master-username $RDS_USERNAME \
    --master-user-password $RDS_PASSWORD \
    --allocated-storage 20 \
    --storage-type gp3 \
    --db-name $RDS_DB_NAME \
    --publicly-accessible \
    --backup-retention-period 7 \
    --region $AWS_REGION \
    2>/dev/null || echo "RDS instance already exists or is being created"

echo -e "${YELLOW}Waiting for RDS to be available (this may take 5-10 minutes)...${NC}"
aws rds wait db-instance-available --db-instance-identifier $RDS_INSTANCE_ID --region $AWS_REGION

# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}RDS Endpoint: ${RDS_ENDPOINT}${NC}"

# ===========================================
# Step 4: Build and Push Docker Image
# ===========================================
echo -e "\n${YELLOW}Step 4: Building and pushing Docker image...${NC}"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Build image
docker build -t $ECR_REPO_NAME:latest .

# Tag and push
docker tag $ECR_REPO_NAME:latest $ECR_URI/$ECR_REPO_NAME:latest
docker push $ECR_URI/$ECR_REPO_NAME:latest

echo -e "${GREEN}Docker image pushed successfully${NC}"

# ===========================================
# Step 5: Create App Runner Service
# ===========================================
echo -e "\n${YELLOW}Step 5: Creating App Runner service...${NC}"

# Generate a secure SECRET_KEY
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')

# Create App Runner configuration
cat > /tmp/apprunner-config.json << EOF
{
    "ServiceName": "${APP_NAME}",
    "SourceConfiguration": {
        "ImageRepository": {
            "ImageIdentifier": "${ECR_URI}/${ECR_REPO_NAME}:latest",
            "ImageConfiguration": {
                "Port": "8000",
                "RuntimeEnvironmentVariables": {
                    "DJANGO_SETTINGS_MODULE": "config.settings.prod",
                    "SECRET_KEY": "${SECRET_KEY}",
                    "DEBUG": "False",
                    "ALLOWED_HOSTS": "*",
                    "DATABASE_URL": "postgres://${RDS_USERNAME}:${RDS_PASSWORD}@${RDS_ENDPOINT}:5432/${RDS_DB_NAME}",
                    "AWS_STORAGE_BUCKET_NAME": "${S3_BUCKET_NAME}",
                    "AWS_S3_REGION_NAME": "${AWS_REGION}"
                }
            },
            "ImageRepositoryType": "ECR"
        },
        "AutoDeploymentsEnabled": true,
        "AuthenticationConfiguration": {
            "AccessRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/AppRunnerECRAccessRole"
        }
    },
    "InstanceConfiguration": {
        "Cpu": "0.25 vCPU",
        "Memory": "0.5 GB"
    },
    "HealthCheckConfiguration": {
        "Protocol": "HTTP",
        "Path": "/health/",
        "Interval": 10,
        "Timeout": 5,
        "HealthyThreshold": 1,
        "UnhealthyThreshold": 5
    }
}
EOF

# First, create the IAM role for App Runner to access ECR
echo -e "${YELLOW}Creating IAM role for App Runner...${NC}"

cat > /tmp/trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "build.apprunner.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

aws iam create-role \
    --role-name AppRunnerECRAccessRole \
    --assume-role-policy-document file:///tmp/trust-policy.json \
    2>/dev/null || echo "Role already exists"

aws iam attach-role-policy \
    --role-name AppRunnerECRAccessRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess \
    2>/dev/null || echo "Policy already attached"

# Wait for role to propagate
sleep 10

# Create App Runner service
aws apprunner create-service \
    --cli-input-json file:///tmp/apprunner-config.json \
    --region $AWS_REGION

echo -e "\n${GREEN}=== Deployment Initiated ===${NC}"
echo -e "App Runner service is being created. This may take a few minutes."
echo -e "\nCheck status with:"
echo -e "  aws apprunner list-services --region $AWS_REGION"
echo -e "\n${YELLOW}Important: After deployment, run migrations:${NC}"
echo -e "  1. Get the App Runner URL from AWS Console"
echo -e "  2. Update ALLOWED_HOSTS and CSRF_TRUSTED_ORIGINS with the URL"
echo -e "  3. Run: python manage.py collectstatic --noinput"
echo -e "\n${YELLOW}DATABASE_URL for your records:${NC}"
echo -e "  postgres://${RDS_USERNAME}:****@${RDS_ENDPOINT}:5432/${RDS_DB_NAME}"
