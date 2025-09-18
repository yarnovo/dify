#!/bin/bash

# Auto-generated script to push Docker images to Aliyun Container Registry
# Generated on: Fri Sep 19 04:10:49 CST 2025
# Target registry: registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors
# Platform: linux/amd64 (for CentOS deployment)

REGISTRY="registry.cn-heyuan.aliyuncs.com"
NAMESPACE="yarnb-docker-mirrors"

echo "Starting to push Docker images to $REGISTRY/$NAMESPACE"
echo "============================================================"
echo ""

# Check if logged in to registry
echo "Checking registry login status..."
if ! docker pull $REGISTRY/$NAMESPACE/test:latest >/dev/null 2>&1; then
    if [ "$?" -ne "1" ]; then
        echo "⚠️  Warning: May not be logged in to $REGISTRY"
        echo "   If push fails, please run: docker login $REGISTRY"
        echo ""
    fi
fi

# Counter for tracking progress
total=0
success=0
failed=0
skipped=0

# Function to tag and push an image
push_image() {
    local original_image="$1"
    local index="$2"
    local total_count="$3"

    echo "[$index/$total_count] Processing: $original_image"

    # Extract image name and tag
    if [[ "$original_image" =~ ^(.+):(.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        tag="${BASH_REMATCH[2]}"
    else
        name="$original_image"
        tag="latest"
    fi

    # Remove any existing registry prefix
    if [[ "$name" =~ ^([^/]+\.[^/]+)/(.+)$ ]]; then
        name="${BASH_REMATCH[2]}"
    fi

    # Replace all / with - in the image name
    clean_name=$(echo "$name" | sed 's|/|-|g')

    # Construct target image name
    target_image="$REGISTRY/$NAMESPACE/${clean_name}:${tag}"

    # Check if the original image exists locally
    if ! docker image inspect "$original_image" >/dev/null 2>&1; then
        echo "  ⚠️  Image not found locally: $original_image"
        echo "     Skipping (run pull-all-images-linux-amd64.sh first)"
        ((skipped++))
        echo ""
        return
    fi

    # Tag the image
    echo "  → Tagging as: $target_image"
    if ! docker tag "$original_image" "$target_image"; then
        echo "  ❌ Failed to tag: $original_image"
        ((failed++))
        echo ""
        return
    fi

    # Push the image
    echo "  → Pushing to registry..."
    if docker push "$target_image"; then
        echo "  ✅ Successfully pushed: $target_image"
        ((success++))
    else
        echo "  ❌ Failed to push: $target_image"
        ((failed++))
    fi

    echo ""
}

# Pull all images
total=27

push_image "certbot/certbot" 1 $total
push_image "container-registry.oracle.com/database/free:latest" 2 $total
push_image "docker.elastic.co/elasticsearch/elasticsearch:8.14.3" 3 $total
push_image "docker.elastic.co/kibana/kibana:8.14.3" 4 $total
push_image "downloads.unstructured.io/unstructured-io/unstructured-api:latest" 5 $total
push_image "ghcr.io/chroma-core/chroma:0.5.20" 6 $total
push_image "langgenius/dify-api:2.0.0-beta.2" 7 $total
push_image "langgenius/dify-plugin-daemon:0.3.0b1-local" 8 $total
push_image "langgenius/dify-sandbox:0.2.12" 9 $total
push_image "langgenius/dify-web:2.0.0-beta.2" 10 $total
push_image "langgenius/qdrant:v1.7.3" 11 $total
push_image "matrixorigin/matrixone:2.1.1" 12 $total
push_image "milvusdb/milvus:v2.5.15" 13 $total
push_image "minio/minio:RELEASE.2023-03-20T20-16-18Z" 14 $total
push_image "myscale/myscaledb:1.6.4" 15 $total
push_image "nginx:latest" 16 $total
push_image "oceanbase/oceanbase-ce:4.3.5-lts" 17 $total
push_image "opengauss/opengauss:7.0.0-RC1" 18 $total
push_image "opensearchproject/opensearch-dashboards:latest" 19 $total
push_image "opensearchproject/opensearch:latest" 20 $total
push_image "pgvector/pgvector:pg16" 21 $total
push_image "postgres:15-alpine" 22 $total
push_image "quay.io/coreos/etcd:v3.5.5" 23 $total
push_image "redis:6-alpine" 24 $total
push_image "semitechnologies/weaviate:1.19.0" 25 $total
push_image "tensorchord/pgvecto-rs:pg16-v0.3.0" 26 $total
push_image "ubuntu/squid:latest" 27 $total

# Print summary
echo "============================================================"
echo "Push Summary:"
echo "  Total images: $total"
echo "  ✅ Successfully pushed: $success"
echo "  ⚠️  Skipped (not found locally): $skipped"
echo "  ❌ Failed: $failed"
echo "============================================================"

if [ $failed -eq 0 ] && [ $skipped -eq 0 ]; then
    echo "🎉 All images pushed successfully!"
    echo ""
    echo "Images are now available at:"
    echo "  $REGISTRY/$NAMESPACE/"
    exit 0
elif [ $skipped -gt 0 ]; then
    echo "⚠️  Some images were skipped because they're not pulled yet."
    echo "   Run ./pull-all-images-linux-amd64.sh first"
    exit 1
else
    echo "❌ Some images failed to push. Please check the errors above."
    exit 1
fi
