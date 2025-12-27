# Dora Novoa - Data Science Portfolio

A professional portfolio website built with Django, showcasing data science projects, skills, and contact information.

## Tech Stack

- **Backend:** Django 5.2, Python 3.12
- **Database:** PostgreSQL 16
- **Frontend:** Bootstrap 5, Django Templates
- **Containerization:** Docker, Docker Compose
- **Production:** AWS ECS Fargate, RDS, S3

## Quick Start
### Prerequisites

- Docker and Docker Compose installed
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Claude-ejemplo1
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
   static/images/profile.jpg
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

## Production Deployment (AWS)

### Architecture

```
                    ┌─────────────┐
                    │   Route 53  │
                    │  (Optional) │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │     ALB     │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼─────┐ ┌────▼────┐ ┌─────▼─────┐
        │ECS Fargate│ │   RDS   │ │    S3     │
        │  (Django) │ │(Postgres)│ │(Static)  │
        └───────────┘ └─────────┘ └───────────┘
```

### Deployment Steps

1. Build and push Docker image to ECR
2. Create RDS PostgreSQL instance
3. Create S3 bucket for static/media files
4. Configure ECS Cluster with Fargate
5. Set up Application Load Balancer
6. Configure environment variables in ECS Task Definition

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

Built with Django and deployed on AWS
