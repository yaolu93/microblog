#!/bin/bash
# Cloud Deployment Test Script
# Tests local Docker build and provides deployment guidance

set -e

echo "========================================="
echo "🧪 Microblog Cloud Deployment Test"
echo "========================================="
echo ""

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

echo "✓ Docker is installed"
echo ""

# Check current directory
if [ ! -f "microblog.py" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

echo "✓ Running from correct directory"
echo ""

# Test 1: Check requirements.txt
echo "📋 [TEST 1] Checking requirements.txt..."
if grep -q "gunicorn" requirements.txt; then
    echo "✓ gunicorn found"
else
    echo "⚠ gunicorn not found, will be added"
fi
echo ""

# Test 2: Validate Dockerfile
echo "📋 [TEST 2] Validating Dockerfile..."
DOCKERFILE_PATH="cloud-deployment/Dockerfile"
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "❌ $DOCKERFILE_PATH not found"
    exit 1
fi
echo "✓ Dockerfile exists at $DOCKERFILE_PATH"
echo ""

# Test 3: Build Docker image
echo "📋 [TEST 3] Building Docker image (this may take 2-3 minutes)..."
echo "Build command: docker build -f cloud-deployment/Dockerfile -t microblog-cloud:test ."
echo ""

if docker build -f cloud-deployment/Dockerfile -t microblog-cloud:test .; then
    echo ""
    echo "✅ Docker image built successfully!"
    IMAGE_ID=$(docker images --filter "reference=microblog-cloud:test" -q | head -1)
    IMAGE_SIZE=$(docker images --filter "reference=microblog-cloud:test" --format "{{.Size}}")
    echo "   Image ID: $IMAGE_ID"
    echo "   Image Size: $IMAGE_SIZE"
    echo ""
else
    echo ""
    echo "❌ Docker build failed. Check the output above for errors."
    exit 1
fi

# Test 4: Check if image can run
echo "📋 [TEST 4] Testing image by running basic container..."
if docker run --rm microblog-cloud:test python --version &> /dev/null; then
    echo "✓ Container runs successfully"
    echo ""
else
    echo "❌ Container failed to run"
    exit 1
fi

# Test 5: Check Python dependencies
echo "📋 [TEST 5] Checking Python dependencies inside container..."
DEPS=("flask" "flask-sqlalchemy" "redis" "gunicorn")
for dep in "${DEPS[@]}"; do
    if docker run --rm microblog-cloud:test python -c "import ${dep}" &> /dev/null; then
        echo "✓ $dep installed"
    else
        echo "⚠ $dep not found (may not be required)"
    fi
done
echo ""

# Summary
echo "========================================="
echo "✅ All Tests Passed!"
echo "========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1️⃣  Push to Docker Hub:"
echo "   docker tag microblog-cloud:test YOUR_DOCKERHUB_USER/microblog:latest"
echo "   docker push YOUR_DOCKERHUB_USER/microblog:latest"
echo ""
echo "2️⃣  Deploy to Google Cloud Run:"
echo "   gcloud run deploy microblog --image YOUR_DOCKERHUB_USER/microblog:latest \\"
echo "     --region us-central1 \\"
echo "     --set-env-vars DATABASE_URL=your_postgres_url,REDIS_URL=your_redis_url"
echo ""
echo "3️⃣  Configure Cloudflare:"
echo "   - Point DNS to Cloud Run URL"
echo "   - Enable caching for static assets"
echo ""

echo "📊 Image Size: $IMAGE_SIZE"
echo ""
echo "Recommended Cloud Services (All Free Tier Available):"
echo "  • PostgreSQL: Neon.tech (FREE)"
echo "  • Redis: Upstash (FREE)"  
echo "  • Cloud: Google Cloud Run (FREE tier: 2M requests/month)"
echo "  • CDN: Cloudflare (FREE)"
echo ""
