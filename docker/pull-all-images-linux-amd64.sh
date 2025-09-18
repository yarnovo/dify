#!/bin/bash

# Auto-generated script to pull all Docker images from docker-compose.yaml
# Generated on: Fri Sep 19 04:10:44 CST 2025
# Platform: linux/amd64

echo "Starting to pull all Docker images (linux/amd64 platform)..."
echo "=================================="
echo ""

# Counter for tracking progress
total=0
success=0
failed=0

# Function to pull an image with error handling
pull_image() {
    local image="$1"
    local index="$2"
    local total="$3"

    echo "[$index/$total] Pulling: $image (linux/amd64 platform)"

    if docker pull --platform linux/amd64 "$image"; then
        echo "✅ Successfully pulled: $image"
        ((success++))
    else
        echo "❌ Failed to pull: $image"
        ((failed++))
    fi
    echo ""
}

# Pull all images
total=27

pull_image "certbot/certbot" 1 $total
pull_image "container-registry.oracle.com/database/free:latest" 2 $total
pull_image "docker.elastic.co/elasticsearch/elasticsearch:8.14.3" 3 $total
pull_image "docker.elastic.co/kibana/kibana:8.14.3" 4 $total
pull_image "downloads.unstructured.io/unstructured-io/unstructured-api:latest" 5 $total
pull_image "ghcr.io/chroma-core/chroma:0.5.20" 6 $total
pull_image "langgenius/dify-api:2.0.0-beta.2" 7 $total
pull_image "langgenius/dify-plugin-daemon:0.3.0b1-local" 8 $total
pull_image "langgenius/dify-sandbox:0.2.12" 9 $total
pull_image "langgenius/dify-web:2.0.0-beta.2" 10 $total
pull_image "langgenius/qdrant:v1.7.3" 11 $total
pull_image "matrixorigin/matrixone:2.1.1" 12 $total
pull_image "milvusdb/milvus:v2.5.15" 13 $total
pull_image "minio/minio:RELEASE.2023-03-20T20-16-18Z" 14 $total
pull_image "myscale/myscaledb:1.6.4" 15 $total
pull_image "nginx:latest" 16 $total
pull_image "oceanbase/oceanbase-ce:4.3.5-lts" 17 $total
pull_image "opengauss/opengauss:7.0.0-RC1" 18 $total
pull_image "opensearchproject/opensearch-dashboards:latest" 19 $total
pull_image "opensearchproject/opensearch:latest" 20 $total
pull_image "pgvector/pgvector:pg16" 21 $total
pull_image "postgres:15-alpine" 22 $total
pull_image "quay.io/coreos/etcd:v3.5.5" 23 $total
pull_image "redis:6-alpine" 24 $total
pull_image "semitechnologies/weaviate:1.19.0" 25 $total
pull_image "tensorchord/pgvecto-rs:pg16-v0.3.0" 26 $total
pull_image "ubuntu/squid:latest" 27 $total

# Print summary
echo "=================================="
echo "Pull Summary:"
echo "  Total images: $total"
echo "  ✅ Successfully pulled: $success"
echo "  ❌ Failed to pull: $failed"
echo "=================================="

if [ $failed -eq 0 ]; then
    echo "🎉 All images pulled successfully!"
    exit 0
else
    echo "⚠️  Some images failed to pull. Please check the errors above."
    exit 1
fi
