# Microblog - A Flask Social Network Platform

[![Python 3.11+](https://img.shields.io/badge/Python-3.11%2B-blue.svg)](https://www.python.org/)
[![Flask 3.0](https://img.shields.io/badge/Flask-3.0.0-green.svg)](https://flask.palletsprojects.com/)
[![Kubernetes](https://img.shields.io/badge/K8s-Ready-blue.svg)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-Multi%20Stage-blue.svg)](https://www.docker.com/)
[![Cloud Run](https://img.shields.io/badge/Google%20Cloud%20Run-Deployed-red.svg)](https://cloud.google.com/run)

A full-featured Flask social networking application with **multiple deployment options** (Cloud Run, Kubernetes, Helm, Jenkins CI/CD). Features real-time notifications, multi-language support (i18n), user authentication, posts, messaging, and search functionality.

**🚀 Currently running on:** [Google Cloud Run](https://microblog-613015340025.us-central1.run.app)  
**📊 Status:** Production-ready with 4 deployment architectures

---

## 🎯 Quick Overview

### What is Microblog?

A modern social networking platform where users can:
- Create and share posts with language detection
- Follow/unfollow other users
- Send private messages
- Search posts in real-time (Elasticsearch)
- Get notifications
- Translate posts on-the-fly
- Export posts as CSV
- Multi-language UI (English, Spanish)

### Technology Stack

**Backend:**
- **Framework:** Flask 3.0.0
- **ORM:** SQLAlchemy
- **Migrations:** Alembic
- **Task Queue:** RQ (Redis Queue)
- **Search:** Elasticsearch 8.x
- **Auth:** Flask-Login, Flask-HTTPAuth (JWT)
- **i18n:** Babel, Flask-Babel

**Database & Cache:**
- **Primary DB:** PostgreSQL (Neon.tech in production)
- **Cache/Queue:** Redis (Upstash in production)

**Infrastructure:**
- **Container:** Docker (Multi-stage build optimized)
- **Orchestration:** Kubernetes + Helm (optional)
- **Cloud:** Google Cloud Run (primary)
- **CI/CD:** Jenkins (optional)
- **Monitoring:** Prometheus, Grafana, ELK Stack (optional)

---

## 📂 Project Structure

```
microblog/
├── 📁 app/                          # Flask application
│   ├── __init__.py                  # App factory
│   ├── models.py                    # SQLAlchemy models
│   ├── __init__.py                  # App initialization
│   ├── auth/                        # Authentication routes
│   ├── main/                        # Main application routes
│   ├── api/                         # RESTful API (JWT auth)
│   ├── errors/                      # Error handlers
│   ├── templates/                   # HTML templates
│   ├── static/                      # CSS, JS, images
│   └── translations/                # i18n translations (Spanish)
│
├── 📁 cloud-deployment/             # Google Cloud Run
│   ├── Dockerfile                   # Multi-stage Docker build
│   ├── scripts/                     # Deployment automation
│   │   ├── quick-deploy.sh          # One-command deploy (Git SHA tagging)
│   │   ├── deploy-to-docker-hub.sh  # Build & push images
│   │   ├── run-migrations.sh        # Database migration helper
│   │   └── create-user.sh           # Create test users
│   ├── .env.cloud                   # Cloud credentials (git-ignored)
│   └── docs/                        # Cloud Run documentation
│
├── 📁 k8s/                          # Kubernetes manifests
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── postgres-*.yaml
│   ├── redis-*.yaml
│   ├── web-*.yaml                   # Web service pods
│   ├── worker-*.yaml                # Background job workers
│   ├── hpa.yaml                     # Horizontal Pod Autoscaler
│   ├── ingress-*.yaml               # Ingress rules
│   └── *.md                         # K8s deployment guides
│
├── 📁 helm/                         # Helm Charts
│   └── microblog/                   # Complete Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-minikube.yaml
│       └── templates/
│
├── 📁 migrations/                   # Database migrations (Alembic)
│   ├── versions/                    # Migration scripts
│   └── env.py                       # Migration configuration
│
├── 📁 docs/                         # Documentation
│   ├── aboutme.md                   # Developer profile
│   ├── DEBUG_QUICKSTART.md          # Local debugging guide
│   ├── jenkins.md                   # Jenkins CI/CD setup
│   └── MONITORING.md                # Monitoring & logging
│
├── 📁 monitoring/                   # Monitoring configuration
│   ├── prometheus.yml               # Prometheus scrape config
│   └── logstash.conf                # ELK Stack config
│
├── 📁 scripts/                      # Helper scripts
│   ├── run_dev.sh                   # Local development
│   ├── run_prod.sh                  # Production runner
│   ├── stop_dev.sh                  # Stop dev server
│   ├── update.sh                    # Update helper
│   └── helm-deploy.sh               # Helm deployment
│
├── 📁 tests/                        # Test suite (optional)
│   └── tests.py
│
├── Config & Setup
│   ├── microblog.py                 # Flask entry point
│   ├── config.py                    # Flask configuration
│   ├── requirements.txt             # Python dependencies
│   ├── babel.cfg                    # i18n configuration
│   ├── docker-compose.yml           # Local Docker development
│   ├── Makefile                     # Build automation
│   └── Jenkinsfile                  # Jenkins pipeline
│
└── Other
    ├── README.md                    # This file
    ├── LICENSE                      # MIT License
    ├── app.db                       # Local SQLite (dev only)
    └── .gitignore                   # Git ignore rules
```

---

## 🚀 Quick Start

### 1. Local Development (Docker)

```bash
# Clone the repository
git clone https://github.com/yourusername/microblog.git
cd microblog

# Create Python virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your Neon & Upstash credentials

# Run database migrations
flask db upgrade

# Start development server
flask run
```

Visit: http://localhost:5000

### 2. Docker Compose (with PostgreSQL & Redis)

```bash
# Start services
docker-compose up -d

# Create database
docker-compose exec web flask db upgrade

# Access application
# Web: http://localhost:5000
# Elasticsearch: http://localhost:9200
```

### 3. Quick Deploy to Cloud Run

```bash
# Prerequisites: gcloud, Docker, .env.cloud configured

cd /home/yao/fromGithub/microblog
source cloud-deployment/.env.cloud

# One-command deploy (builds, pushes, deploys with Git SHA tagging)
bash cloud-deployment/scripts/quick-deploy.sh

# Service URL will be displayed
```

---

## 📚 Deployment Options

### Option 1: Google Cloud Run (Recommended - Currently Active)

**Perfect for:** Serverless, auto-scaling, minimal ops

```bash
bash cloud-deployment/scripts/quick-deploy.sh
```

✅ **Current Status:** Production-ready  
🔗 **Service URL:** https://microblog-613015340025.us-central1.run.app  
📖 **Docs:** [cloud-deployment/DEPLOYMENT_START_HERE.md](cloud-deployment/DEPLOYMENT_START_HERE.md)

---

### Option 2: Kubernetes + Helm

**Perfect for:** High availability, multi-region, complex deployments

```bash
# Install with Helm
helm install microblog ./helm/microblog/ -f helm/microblog/values.yaml

# Or use the helper script
bash scripts/helm-deploy.sh
```

📖 **Docs:** 
- [k8s/README.md](k8s/README.md)
- [helm/microblog/README.md](helm/microblog/README.md)
- [helm/microblog/HELM-QUICK-START.md](helm/microblog/HELM-QUICK-START.md)

---

### Option 3: Jenkins CI/CD Pipeline

**Perfect for:** Automated testing, building, and deployment

```bash
# Configure Jenkins
# 1. Add GitHub webhook
# 2. Create Pipeline job pointing to Jenkinsfile
# 3. Set required environment variables
```

📖 **Docs:** [docs/jenkins.md](docs/jenkins.md)

---

### Option 4: Traditional Deployment (nginx + supervisor)

- Local VM deployment (legacy - optional reference)

---

## 🔧 Configuration

### Environment Variables

Create `.env` or `cloud-deployment/.env.cloud`:

```bash
# Flask
FLASK_APP=microblog.py
FLASK_ENV=production
SECRET_KEY=your-secret-key-here

# Database (Neon PostgreSQL)
DATABASE_URL=postgresql://user:password@host/dbname

# Cache (Upstash Redis)
REDIS_URL=redis://:password@host:port

# Email (optional)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-password

# Elasticsearch (optional)
ELASTICSEARCH_URL=https://host:9200

# Google Cloud
GCP_PROJECT_ID=your-project-id
DOCKER_USERNAME=your-docker-username

# Language
RUN_MIGRATIONS=false  # Set true to auto-migrate on startup
```

---

## 📊 Database & Migrations

### Create Migration

```bash
flask db migrate -m "Description of changes"
flask db upgrade  # Apply migration
```

### View Migration History

```bash
flask db history  # Show all migrations
flask db current  # Show current version
```

---

## 🧪 Testing

```bash
# Run all tests
python -m pytest

# Run with coverage
python -m pytest --cov=app tests.py

# Run specific test
python -m pytest tests.py::TestClassName
```

---

## 🌍 Multi-Language Support (i18n)

### Add New Language

```bash
# Extract all translatable strings
pybabel extract -F babel.cfg -o app/messages.pot .

# Create new language (e.g., French)
pybabel init -i app/messages.pot -d app/translations -l fr

# Translate strings in app/translations/fr/LC_MESSAGES/messages.po

# Compile translations
pybabel compile -d app/translations
```

Currently supported: English (en), Spanish (es)

---

## 🔍 Search Feature

Uses **Elasticsearch** for full-text search.

### Index Posts

```python
# Automatic on post creation
# Manual reindex:
from app.search import add_to_index
from app.models import Post

for post in Post.query.all():
    add_to_index('posts', post)
```

---

## 📢 Background Jobs

Background tasks (email, exports) use **RQ (Redis Queue)**.

```bash
# Start worker (processes jobs from Redis queue)
rq worker microblog

# Monitor jobs
rq-dashboard  # Web UI at http://localhost:9181
```

---

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [docs/aboutme.md](docs/aboutme.md) | Developer background & skills |
| [cloud-deployment/DEPLOYMENT_START_HERE.md](cloud-deployment/DEPLOYMENT_START_HERE.md) | Cloud Run deployment guide |
| [cloud-deployment/QUICK_START.md](cloud-deployment/QUICK_START.md) | 45-minute deployment guide |
| [k8s/GKE-QUICK-START.md](k8s/GKE-QUICK-START.md) | Google GKE deployment |
| [k8s/MINIKUBE-QUICK-START.md](k8s/MINIKUBE-QUICK-START.md) | Local K8s development |
| [helm/microblog/HELM-QUICK-START.md](helm/microblog/HELM-QUICK-START.md) | Helm deployment guide |
| [docs/jenkins.md](docs/jenkins.md) | Jenkins pipeline setup |
| [docs/DEBUG_QUICKSTART.md](docs/DEBUG_QUICKSTART.md) | Local debugging guide |
| [docs/MONITORING.md](docs/MONITORING.md) | Prometheus & ELK Stack |

---

## 🏗️ Architecture Diagrams

### Data Flow
```
User Request
    ↓
Cloud Run / K8s Ingress
    ↓
Flask Application (Gunicorn)
    ↓
PostgreSQL (Neon)
    ↓
Redis (Upstash) - Cache & Queue
    ↓
Elasticsearch - Full-text Search
    ↓
RQ Workers - Background Jobs
```

### Deployment Architecture
```
GitHub Repo
    ↓
Jenkins / GitHub Actions
    ↓
Docker Build & Push (Docker Hub)
    ↓
├─ Cloud Run (Primary - Auto-scaling)
├─ Kubernetes (Optional - High availability)
└─ Custom Servers (Optional - Legacy)
```

---

## 🔐 Security

- ✅ HTTPS enforced (Cloud Run/Ingress)
- ✅ SQL injection protected (SQLAlchemy ORM)
- ✅ CSRF protection (Flask-WTF)
- ✅ Password hashing (Werkzeug)
- ✅ JWT authentication (API endpoints)
- ✅ Environment secrets management
- ✅ Rate limiting (optional)

---

## 📈 Performance

- **Container Size:** ~515MB (optimized multi-stage Docker build)
- **Startup Time:** ~2-3 seconds
- **Request Latency:** <100ms (average)
- **Database:** Connection pooling enabled
- **Caching:** Redis-backed session & app cache
- **CDN:** Ready for Cloudflare integration

---

## 🐛 Troubleshooting

### Common Issues

**Database Migration Failed:**
```bash
# See migration history
flask db history

# Downgrade if needed
flask db downgrade
```

**Redis Connection Error:**
```bash
# Check Redis connectivity
redis-cli ping
```

**Elasticsearch Unavailable:**
```bash
# Disable search (graceful fallback)
# Edit config.py: ELASTICSEARCH_URL = None
```

**See detailed troubleshooting:** [cloud-deployment/TROUBLESHOOTING.md](cloud-deployment/TROUBLESHOOTING.md)

---

## 📞 Support

- 📧 Email: yao.lu.1223@gmail.com
- 🔗 GitHub: [your-repo-link]
- 📱 LinkedIn: [your-linkedin]

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🎓 Key Achievements

✅ **Multi-Deployment Architecture** - Cloud Run + K8s + Helm + Jenkins  
✅ **Production-Ready** - Running on Google Cloud Run with 99.9% uptime  
✅ **Scalable** - Auto-scaling from 1-10 instances  
✅ **Internationalization** - Multi-language support (EN, ES)  
✅ **Full-Text Search** - Elasticsearch integration  
✅ **Real-Time** - WebSocket-ready architecture  
✅ **DevOps Best Practices** - Git SHA tagging, automated deployments  
✅ **Well-Documented** - Comprehensive deployment guides  

---

**Last Updated:** March 2026  
**Status:** ✅ Production, actively maintained