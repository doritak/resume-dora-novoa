# Dora Novoa - Data Science Portfolio

A professional portfolio website built with Django, showcasing data science projects, skills, and contact information.

## Tech Stack

- **Backend:** Django 5.2, Python 3.12
- **Database:** PostgreSQL 16
- **Frontend:** Bootstrap 5, Django Templates
- **Containerization:** Docker, Docker Compose
- **Production:** AWS App Runner, RDS, S3

## Quick Start
### Prerequisites

- Docker and Docker Compose installed
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Resume-Dora-Novoa
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Start the containers:**
   ```bash
   docker-compose up -d
   ```

4. **Run migrations:**
   ```bash
   docker-compose exec web python manage.py migrate
   ```

5. **Create a superuser:**
   ```bash
   docker-compose exec web python manage.py createsuperuser
   ```

6. **Access the site:**
   - Portfolio: http://localhost:8000
   - Admin: http://localhost:8000/admin

## Project Structure

```
├── apps/
│   ├── core/           # Home and About pages
│   ├── projects/       # Data Science projects showcase
│   └── contact/        # Contact form with email notifications
├── config/
│   ├── settings/
│   │   ├── base.py     # Shared settings
│   │   ├── dev.py      # Development settings
│   │   └── prod.py     # Production settings (AWS, SSL)
│   ├── urls.py
│   └── wsgi.py
├── templates/          # Base templates
├── static/             # CSS, JS, images
├── media/              # User uploads
├── requirements/       # Dependencies (base, dev, prod)
├── Dockerfile
└── docker-compose.yml
```

## Features

- **Home Page:** Hero section with profile, skills overview, featured projects
- **Projects:** Grid display with technology filters, detail pages
- **About:** Professional background, education, technical skills
- **Contact:** Form with email notifications (AWS SES ready)
- **Admin Panel:** Manage projects and view contact messages
- **Responsive:** Mobile-friendly Bootstrap 5 design

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Debug mode | `True` |
| `SECRET_KEY` | Django secret key | Required |
| `DATABASE_URL` | PostgreSQL connection | `postgres://...` |
| `ALLOWED_HOSTS` | Comma-separated hosts | `localhost,127.0.0.1` |
| `AWS_ACCESS_KEY_ID` | AWS credentials | - |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials | - |
| `AWS_STORAGE_BUCKET_NAME` | S3 bucket for static/media | - |
| `CONTACT_EMAIL` | Email for contact notifications | - |

### Adding Your Content

1. **Profile Photo:**
   ```
   static/images/profile.png
   ```

2. **Resume/CV:**
   ```
   static/cv/resume.pdf
   ```

3. **Social Links:**
   Edit `templates/base.html` to update GitHub and LinkedIn URLs.

4. **Projects:**
   Add via Django Admin at `/admin/projects/project/`

## Development

### Useful Commands

```bash
# View logs
docker-compose logs -f web

# Django shell
docker-compose exec web python manage.py shell

# Create new migrations
docker-compose exec web python manage.py makemigrations

# Run tests
docker-compose exec web python manage.py test

# Collect static files
docker-compose exec web python manage.py collectstatic
```

### Running Without Docker

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install dependencies
pip install -r requirements/dev.txt

# Set environment variables
export DJANGO_SETTINGS_MODULE=config.settings.dev
export DATABASE_URL=postgres://user:pass@localhost:5432/portfolio

# Run migrations and server
python manage.py migrate
python manage.py runserver
```

## Production Deployment (AWS App Runner)

### Architecture

```
                    ┌─────────────┐
                    │   Route 53  │
                    │  (Optional) │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ App Runner  │◄──── Auto-scaling
                    │  (Django)   │      HTTPS included
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
        ┌─────▼─────┐             ┌─────▼─────┐
        │    RDS    │             │    S3     │
        │(PostgreSQL)│            │ (Static)  │
        └───────────┘             └───────────┘
```

### Why App Runner?

| Feature | App Runner | ECS Fargate |
|---------|-----------|-------------|
| Load Balancer | Included | ~$16-22/month extra |
| NAT Gateway | Not needed | ~$32/month extra |
| Configuration | Simple | Complex |
| Auto-scaling | Built-in | Manual setup |
| **Estimated Cost** | **~$20-35/mo** | **~$50-85/mo** |

### Quick Deploy

```bash
cd deploy
./deploy-apprunner.sh
```

### Manual Deployment Steps

1. **Create ECR Repository:**
   ```bash
   aws ecr create-repository --repository-name resume-dora-novoa
   ```

2. **Build and Push Docker Image:**
   ```bash
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

   # Build and push
   docker build -t resume-dora-novoa .
   docker tag resume-dora-novoa:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/resume-dora-novoa:latest
   docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/resume-dora-novoa:latest
   ```

3. **Create RDS PostgreSQL Instance:**
   ```bash
   aws rds create-db-instance \
     --db-instance-identifier resume-db \
     --db-instance-class db.t4g.micro \
     --engine postgres \
     --master-username dbadmin \
     --master-user-password YOUR_PASSWORD \
     --allocated-storage 20
   ```

4. **Create S3 Bucket:**
   ```bash
   aws s3 mb s3://resume-dora-novoa-static
   ```

5. **Create App Runner Service** via AWS Console or CLI with environment variables

6. **Post-deployment:**
   ```bash
   python manage.py collectstatic --noinput
   python manage.py migrate
   ```

See `deploy/README.md` for detailed instructions.

## Models

### Project
- `title` - Project name
- `slug` - URL-friendly identifier
- `description` - Full project description
- `technologies` - JSON array of tech used
- `image` - Project thumbnail
- `github_url` - Link to repository
- `demo_url` - Live demo link
- `notebook_url` - Colab/Kaggle notebook
- `featured` - Show on homepage

### ContactMessage
- `name` - Sender name
- `email` - Sender email
- `subject` - Message subject
- `message` - Message content
- `is_read` - Read status flag

## License

MIT License

## Author

**Dora Novoa**
Data Scientist | Software Engineer

---

Built with Django and deployed on AWS App Runner
