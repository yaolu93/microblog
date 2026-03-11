#!/bin/bash
# deploy-to-docker-hub.sh - Build and push Docker image to Docker Hub
# Uses Git commit SHA for automatic versioning (DevOps best practice)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME=${1:-}
USE_GIT_SHA=${2:-true}  # Automatically use Git SHA by default

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}❌ Usage: ./deploy-to-docker-hub.sh <DOCKER_USERNAME> [use-git-sha]${NC}"
    echo "Example:"
    echo "  # Auto-tag with Git SHA (recommended):"
    echo "  ./deploy-to-docker-hub.sh john"
    echo ""
    echo "  # Or use explicit version:"
    echo "  ./deploy-to-docker-hub.sh john false"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🐳 Docker Hub Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get Git information
if [ "$USE_GIT_SHA" = "true" ]; then
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}⚠ Git not found, falling back to 'latest'${NC}"
        GIT_SHA="latest"
    else
        GIT_SHA=$(git rev-parse --short HEAD)
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        GIT_MSG=$(git log -1 --pretty=%B | head -n 1)
        
        echo -e "${BLUE}📝 Git Info:${NC}"
        echo "  Commit SHA: $GIT_SHA"
        echo "  Branch: $GIT_BRANCH"
        echo "  Message: $GIT_MSG"
        echo ""
    fi
else
    GIT_SHA="latest"
fi

# Step 1: Check Docker
echo -e "${YELLOW}[1/5]${NC} Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

# Step 2: Check authentication
echo -e "${YELLOW}[2/5]${NC} Checking Docker Hub authentication..."
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓ Docker is accessible${NC}"
else
    echo -e "${YELLOW}⚠ Docker may not be authenticated. Proceeding...${NC}"
fi
echo ""

# Step 3: Build image with multiple tags
echo -e "${YELLOW}[3/5]${NC} Building Docker image..."
echo "  Tags:"
echo "    - ${DOCKER_USERNAME}/microblog:${GIT_SHA}"
echo "    - ${DOCKER_USERNAME}/microblog:latest"
echo ""

IMAGE_TAG="$DOCKER_USERNAME/microblog:$GIT_SHA"

if docker build \
    -f cloud-deployment/Dockerfile \
    -t "$IMAGE_TAG" \
    -t "$DOCKER_USERNAME/microblog:latest" \
    .; then
    echo -e "${GREEN}✓ Image built successfully${NC}"
    DIGEST=$(docker images --no-trunc --quiet "$IMAGE_TAG" | cut -c1-12)
    IMAGE_SIZE=$(docker images --format "{{.Size}}" "$IMAGE_TAG")
    echo "  Digest: $DIGEST"
    echo "  Size: $IMAGE_SIZE"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo ""

# Step 4: Push to Docker Hub
echo -e "${YELLOW}[4/5]${NC} Pushing images to Docker Hub..."
echo "This may take a few minutes..."
echo ""

# Push versioned tag
if docker push "$IMAGE_TAG"; then
    echo -e "${GREEN}✓ Pushed: $IMAGE_TAG${NC}"
else
    echo -e "${RED}❌ Push failed for $IMAGE_TAG${NC}"
    exit 1
fi

# Push latest tag
if docker push "$DOCKER_USERNAME/microblog:latest"; then
    echo -e "${GREEN}✓ Pushed: ${DOCKER_USERNAME}/microblog:latest${NC}"
else
    echo -e "${RED}❌ Push failed for latest tag${NC}"
    exit 1
fi
echo ""

# Step 5: Verify
echo -e "${YELLOW}[5/5]${NC} Verifying images..."
echo "Pulling ${DOCKER_USERNAME}/microblog:${GIT_SHA}..."
if docker pull "$IMAGE_TAG" &> /dev/null; then
    echo -e "${GREEN}✓ Image verified${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify immediately (may take a minute)${NC}"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Docker Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📦 Image Information:"
echo "  Repository: $DOCKER_USERNAME/microblog"
echo "  Tags: $GIT_SHA, latest"
echo "  Docker Hub: https://hub.docker.com/r/$DOCKER_USERNAME/microblog"
echo ""
echo "🚀 Next: Deploy to Google Cloud Run"
echo "  gcloud run deploy microblog \\"
echo "    --image $IMAGE_TAG \\"
echo "    --region us-central1 \\"
echo "    --project \$GCP_PROJECT_ID"
echo ""

