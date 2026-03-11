#!/bin/bash
# deploy-to-docker-hub.sh - Push Docker image to Docker Hub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME=${1:-}
VERSION=${2:-latest}

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}❌ Usage: ./deploy-to-docker-hub.sh <DOCKER_USERNAME> [VERSION]${NC}"
    echo "Example: ./deploy-to-docker-hub.sh john latest"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🐳 Docker Hub Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check Docker
echo -e "${YELLOW}[1/5]${NC} Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

# Step 2: Login to Docker Hub
echo -e "${YELLOW}[2/5]${NC} Login to Docker Hub..."
if docker login -u "$DOCKER_USERNAME" 2>&1 | grep -q "Login Succeeded"; then
    echo -e "${GREEN}✓ Logged in successfully${NC}"
else
    echo -e "${YELLOW}⚠ Ensure you're logged in to Docker Hub${NC}"
fi
echo ""

# Step 3: Build image
echo -e "${YELLOW}[3/5]${NC} Building Docker image..."
IMAGE_TAG="$DOCKER_USERNAME/microblog:$VERSION"
if docker build -f cloud-deployment/Dockerfile -t "$IMAGE_TAG" -t "$DOCKER_USERNAME/microblog:latest" .; then
    echo -e "${GREEN}✓ Image built successfully${NC}"
    DIGEST=$(docker images --no-trunc --quiet "$IMAGE_TAG")
    echo "  Image: $IMAGE_TAG"
    echo "  Digest: $DIGEST"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo ""

# Step 4: Push to Docker Hub
echo -e "${YELLOW}[4/5]${NC} Pushing to Docker Hub..."
echo "This may take a few minutes..."
echo ""

if docker push "$IMAGE_TAG"; then
    echo -e "${GREEN}✓ Image pushed successfully${NC}"
    echo "  Image: $IMAGE_TAG"
else
    echo -e "${RED}❌ Push failed${NC}"
    exit 1
fi

if docker push "$DOCKER_USERNAME/microblog:latest"; then
    echo -e "${GREEN}✓ Latest tag pushed successfully${NC}"
fi
echo ""

# Step 5: Verify
echo -e "${YELLOW}[5/5]${NC} Verifying image..."
if docker pull "$IMAGE_TAG" &> /dev/null; then
    echo -e "${GREEN}✓ Image verified - can be pulled from Docker Hub${NC}"
else
    echo -e "${YELLOW}⚠ Could not pull image immediately (may take a minute)${NC}"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Deployment to Docker Hub Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy to Google Cloud Run:"
echo "   gcloud run deploy microblog \\"
echo "     --image $IMAGE_TAG \\"
echo "     --region us-central1"
echo ""
echo "2. Check Docker Hub:"
echo "   https://hub.docker.com/r/$DOCKER_USERNAME/microblog"
echo ""
