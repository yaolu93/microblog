#!/bin/bash
# deploy-to-cloud-run.sh - Deploy Docker image to Google Cloud Run

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ID=${1:-}
DOCKER_IMAGE=${2:-}
SERVICE_NAME=${3:-microblog}
REGION=${4:-us-central1}

if [ -z "$PROJECT_ID" ] || [ -z "$DOCKER_IMAGE" ]; then
    echo -e "${RED}❌ Usage: ./deploy-to-cloud-run.sh <PROJECT_ID> <DOCKER_IMAGE> [SERVICE_NAME] [REGION]${NC}"
    echo "Example: ./deploy-to-cloud-run.sh my-project john/microblog:latest microblog us-central1"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}☁️  Google Cloud Run Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check gcloud CLI
echo -e "${YELLOW}[1/6]${NC} Checking Google Cloud CLI..."
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
echo -e "${GREEN}✓ Google Cloud CLI is installed${NC}"
echo ""

# Step 2: Check authentication
echo -e "${YELLOW}[2/6]${NC} Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${YELLOW}⚠ Not authenticated. Running gcloud auth login...${NC}"
    gcloud auth login
fi
echo -e "${GREEN}✓ Authenticated${NC}"
echo ""

# Step 3: Set project
echo -e "${YELLOW}[3/6]${NC} Setting project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"
echo -e "${GREEN}✓ Project set${NC}"
echo ""

# Step 4: Check/Create Cloud Run API
echo -e "${YELLOW}[4/6]${NC} Checking Cloud Run API..."
if gcloud services list --enabled --filter="name:run.googleapis.com" | grep -q run.googleapis.com; then
    echo -e "${GREEN}✓ Cloud Run API is enabled${NC}"
else
    echo -e "${YELLOW}⚠ Enabling Cloud Run API...${NC}"
    gcloud services enable run.googleapis.com
fi
echo ""

# Step 5: Read environment variables (if exists)
ENV_VARS=""
if [ -f ".env.gcp" ]; then
    echo -e "${YELLOW}[5/6]${NC} Loading environment variables from .env.gcp..."
    set -a
    source .env.gcp
    set +a
    
    ENV_VARS="DATABASE_URL=$DATABASE_URL,REDIS_URL=$REDIS_URL,FLASK_ENV=production,LOG_TO_STDOUT=true,RUN_MIGRATIONS=true"
    echo -e "${GREEN}✓ Environment variables loaded${NC}"
else
    echo -e "${YELLOW}[5/6]${NC} .env.gcp not found${NC}"
    echo -e "${YELLOW}⚠ You must set environment variables during deployment${NC}"
    echo ""
    echo "Create .env.gcp with:"
    echo "  DATABASE_URL=postgresql://..."
    echo "  REDIS_URL=redis://..."
fi
echo ""

# Step 6: Deploy to Cloud Run
echo -e "${YELLOW}[6/6]${NC} Deploying to Cloud Run..."
echo ""

DEPLOY_CMD="gcloud run deploy $SERVICE_NAME \
  --image=$DOCKER_IMAGE \
  --platform=managed \
  --region=$REGION \
  --memory=512Mi \
  --timeout=300 \
  --allow-unauthenticated \
  --set-env-vars=$ENV_VARS"

echo "Deployment command:"
echo "$DEPLOY_CMD"
echo ""

if eval "$DEPLOY_CMD"; then
    echo -e "${GREEN}✓ Deployment successful${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi
echo ""

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format='value(status.url)')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Cloud Run Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Service Details:"
echo "  Name: $SERVICE_NAME"
echo "  Region: $REGION"
echo "  Image: $DOCKER_IMAGE"
echo "  URL: $SERVICE_URL"
echo ""
echo "Useful commands:"
echo ""
echo "📊 View logs:"
echo "  gcloud run logs read $SERVICE_NAME --limit 100"
echo ""
echo "🔄 View revisions:"
echo "  gcloud run revisions list --service=$SERVICE_NAME"
echo ""
echo "🔄 Update service:"
echo "  gcloud run services update $SERVICE_NAME --image=NEW_IMAGE"
echo ""
echo "🗑️  Delete service:"
echo "  gcloud run services delete $SERVICE_NAME"
echo ""
echo "🧪 Test the service:"
echo "  curl $SERVICE_URL"
echo ""
echo "📝 Next step: Configure Cloudflare"
echo "  Point your domain to: $SERVICE_URL"
echo ""
