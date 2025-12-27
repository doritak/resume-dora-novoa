# AWS App Runner Deployment Guide

## Prerequisites

1. **AWS CLI** configured with your credentials:
   ```bash
   aws configure
   ```

2. **Docker** installed and running

3. **jq** installed (for JSON parsing):
   ```bash
   brew install jq
   ```

## Quick Deploy

### Option 1: Automated Script

```bash
cd deploy
./deploy-apprunner.sh
```

### Option 2: Manual Steps

#### Step 1: Create ECR Repository
```bash
aws ecr create-repository --repository-name resume-dora-novoa --region us-east-1
```

#### Step 2: Create S3 Bucket
```bash
aws s3 mb s3://resume-dora-novoa-static --region us-east-1
```

#### Step 3: Create RDS Instance
```bash
aws rds create-db-instance \
    --db-instance-identifier resume-dora-novoa-db \
    --db-instance-class db.t4g.micro \
    --engine postgres \
    --engine-version 16 \
    --master-username dbadmin \
    --master-user-password YOUR_PASSWORD \
    --allocated-storage 20 \
    --storage-type gp3 \
    --db-name portfolio \
    --publicly-accessible \
    --region us-east-1
```

#### Step 4: Build and Push Docker Image
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build
docker build -t resume-dora-novoa .

# Tag
docker tag resume-dora-novoa:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/resume-dora-novoa:latest

# Push
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/resume-dora-novoa:latest
```

#### Step 5: Create App Runner Service
Use the AWS Console or CLI to create the App Runner service with:
- **Source**: ECR image
- **Port**: 8000
- **Health check**: /health/
- **Instance**: 0.25 vCPU, 0.5 GB RAM

## Environment Variables for App Runner

Set these in App Runner service configuration:

| Variable | Description |
|----------|-------------|
| `SECRET_KEY` | Django secret key |
| `DEBUG` | `False` |
| `ALLOWED_HOSTS` | `your-app.us-east-1.awsapprunner.com` |
| `CSRF_TRUSTED_ORIGINS` | `https://your-app.us-east-1.awsapprunner.com` |
| `DATABASE_URL` | `postgres://user:pass@rds-endpoint:5432/dbname` |
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `AWS_STORAGE_BUCKET_NAME` | S3 bucket name |
| `AWS_S3_REGION_NAME` | `us-east-1` |

## Post-Deployment

After the service is running:

1. **Upload static files**:
   ```bash
   # Set environment variables locally
   export AWS_ACCESS_KEY_ID=xxx
   export AWS_SECRET_ACCESS_KEY=xxx
   export AWS_STORAGE_BUCKET_NAME=resume-dora-novoa-static
   export DJANGO_SETTINGS_MODULE=config.settings.prod

   python manage.py collectstatic --noinput
   ```

2. **Run migrations** (via AWS CLI exec or local with RDS connection):
   ```bash
   export DATABASE_URL=postgres://user:pass@rds-endpoint:5432/dbname
   python manage.py migrate
   ```

## Cost Estimation

| Service | Monthly Cost |
|---------|-------------|
| App Runner (0.25 vCPU, 0.5 GB) | ~$5-15 |
| RDS t4g.micro | ~$12-15 |
| S3 (low usage) | ~$1-2 |
| ECR | ~$1 |
| **Total** | **~$20-35/month** |

## Updating the Application

Push a new image to ECR, and App Runner will auto-deploy:

```bash
docker build -t resume-dora-novoa .
docker tag resume-dora-novoa:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/resume-dora-novoa:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/resume-dora-novoa:latest
```

## Cleanup

To delete all resources:

```bash
# Delete App Runner service
aws apprunner delete-service --service-arn YOUR_SERVICE_ARN

# Delete RDS
aws rds delete-db-instance --db-instance-identifier resume-dora-novoa-db --skip-final-snapshot

# Delete S3 bucket
aws s3 rb s3://resume-dora-novoa-static --force

# Delete ECR repository
aws ecr delete-repository --repository-name resume-dora-novoa --force
```
