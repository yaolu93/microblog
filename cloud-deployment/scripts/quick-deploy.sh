#!/bin/bash
# quick-deploy.sh - One-command full deployment pipeline
# Builds, pushes to Docker Hub, and deploys to Cloud Run
# Uses Git commit SHA for automatic versioning

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get environment variables
DOCKER_USERNAME=${DOCKER_USERNAME:-}
GCP_PROJECT_ID=${GCP_PROJECT_ID:-}
SERVICE_NAME="microblog"
REGION="us-central1"

# Print header
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[$1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Validate environment
validate_env() {
    print_step "1/6" "Validating environment..."
    
    if [ -z "$DOCKER_USERNAME" ]; then
        print_error "DOCKER_USERNAME not set. Run: source .env.cloud"
    fi
    
    if [ -z "$GCP_PROJECT_ID" ]; then
        print_error "GCP_PROJECT_ID not set. Run: source .env.cloud"
    fi
    
    # Check required tools
    command -v docker &> /dev/null || print_error "Docker is not installed"
    command -v git &> /dev/null || print_error "Git is not installed"
    command -v gcloud &> /dev/null || print_error "gcloud CLI is not installed"
    
    print_success "All required tools are available"
    echo ""
}

# Get Git information
get_git_info() {
    print_step "2/6" "Getting Git information..."
    
    GIT_SHA=$(git rev-parse --short=7 HEAD)
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    GIT_MSG=$(git log -1 --pretty=%B | head -n 1)
    
    echo "  Commit: $GIT_SHA ($GIT_BRANCH)"
    echo "  Message: $GIT_MSG"
    
    IMAGE_TAG="$DOCKER_USERNAME/$SERVICE_NAME:$GIT_SHA"
    echo "  Image tag: $IMAGE_TAG"
    echo ""
    
    print_success "Git info retrieved"
    echo ""
}

# Build and push Docker image
build_and_push() {
    print_step "3/6" "Building and pushing Docker image..."
    
    cd - > /dev/null 2>&1 || cd /home/yao/fromGithub/microblog
    
    echo "  Building with tags:"
    echo "    - $IMAGE_TAG"
    echo "    - $DOCKER_USERNAME/$SERVICE_NAME:latest"
    echo ""
    
    docker build \
        -f cloud-deployment/Dockerfile \
        -t "$IMAGE_TAG" \
        -t "$DOCKER_USERNAME/$SERVICE_NAME:latest" \
        . || print_error "Docker build failed"
    
    print_success "Image built"
    echo ""
    
    echo "  Pushing to Docker Hub..."
    docker push "$IMAGE_TAG" || print_error "Push $IMAGE_TAG failed"
    docker push "$DOCKER_USERNAME/$SERVICE_NAME:latest" || print_error "Push latest failed"
    
    print_success "Image pushed to Docker Hub"
    echo ""
}

# Deploy to Cloud Run
deploy_to_cloud_run() {
    print_step "4/6" "Deploying to Cloud Run..."
    
    gcloud run deploy "$SERVICE_NAME" \
        --image "$IMAGE_TAG" \
        --region "$REGION" \
        --project "$GCP_PROJECT_ID" || print_error "Cloud Run deployment failed"
    
    print_success "Deployed to Cloud Run"
    echo ""
}

# Get service URL
get_service_url() {
    print_step "5/6" "Getting service URL..."
    
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
        --region "$REGION" \
        --project "$GCP_PROJECT_ID" \
        --format='value(status.url)')
    
    echo "  Service URL: $SERVICE_URL"
    echo ""
    
    print_success "Service URL retrieved"
    echo ""
}

# Verify deployment
verify_deployment() {
    print_step "6/6" "Verifying deployment..."
    
    echo ""
    echo "Waiting for service to be ready..."
    sleep 5
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/health" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "Health check passed (HTTP $HTTP_CODE)"
    else
        echo -e "${YELLOW}⚠ Health check returned HTTP $HTTP_CODE (may still be starting)${NC}"
    fi
    echo ""
}

# Main execution
main() {
    print_header "🚀 Complete Deployment Pipeline"
    echo "Service: $SERVICE_NAME"
    echo "Region: $REGION"
    echo "Docker: $DOCKER_USERNAME"
    echo "GCP Project: $GCP_PROJECT_ID"
    echo ""
    
    validate_env
    get_git_info
    build_and_push
    deploy_to_cloud_run
    get_service_url
    verify_deployment
    
    # Final summary
    print_header "✅ Deployment Complete!"
    echo ""
    echo -e "${CYAN}📊 Deployment Summary:${NC}"
    echo "  Commit: $GIT_SHA"
    echo "  Branch: $GIT_BRANCH"
    echo "  Image: $IMAGE_TAG"
    echo "  Service: $SERVICE_NAME"
    echo "  Region: $REGION"
    echo "  URL: $SERVICE_URL"
    echo ""
    
    echo -e "${CYAN}🔗 Quick Links:${NC}"
    echo "  Service: $SERVICE_URL"
    echo "  Logs: gcloud logging read \"resource.labels.service_name=$SERVICE_NAME\" --limit 50"
    echo "  Docker Hub: https://hub.docker.com/r/$DOCKER_USERNAME/$SERVICE_NAME"
    echo ""
    
    echo -e "${CYAN}📝 To rollback to previous revision:${NC}"
    echo "  gcloud run services update-traffic $SERVICE_NAME --to-revisions <revision-name>=100 --region $REGION"
    echo ""
}

# Run if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
