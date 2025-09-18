#!/bin/bash

# Auto-generated script to pull all Docker images from docker-compose.yaml
# Generated on: Fri Sep 19 06:13:25 CST 2025
# Platform: linux/amd64

echo "Starting to pull all Docker images (linux/amd64 platform)..."
echo "=================================="
echo ""

# Counter for tracking progress
total=0
success=0
failed=0

# Function to pull an image with error handling and digest fallback
pull_image() {
    local image="$1"
    local index="$2"
    local total="$3"

    echo "[$index/$total] Processing: $image"

    # First, try to pull with --platform
    echo "  → Attempting to pull with --platform linux/amd64..."
    if docker pull --platform linux/amd64 "$image"; then
        # Check if we actually got AMD64
        arch=$(docker image inspect "$image" --format '{{.Architecture}}' 2>/dev/null)

        if [ "$arch" = "amd64" ] || [ "$arch" = "x86_64" ]; then
            echo "  ✅ Successfully pulled AMD64 version"
            ((success++))
        else
            echo "  ⚠️  Got $arch instead of amd64, trying digest method..."

            # Remove the wrong architecture version
            docker rmi "$image" --force 2>/dev/null || true

            # Try to get AMD64 digest
            echo "  → Getting AMD64 digest from manifest..."
            amd64_digest=$(docker manifest inspect "$image" 2>/dev/null | jq -r '.manifests[] | select(.platform.architecture == "amd64") | .digest' | head -1)

            if [ -n "$amd64_digest" ] && [ "$amd64_digest" != "null" ]; then
                echo "  → Found digest: $amd64_digest"

                # Extract base image name without tag
                if [[ "$image" == *:* ]]; then
                    base_image="${image%:*}"
                    tag="${image#*:}"
                else
                    base_image="$image"
                    tag="latest"
                fi

                # Pull by digest
                echo "  → Pulling by digest..."
                if docker pull "${base_image}@${amd64_digest}"; then
                    # Tag it properly
                    docker tag "${base_image}@${amd64_digest}" "$image"

                    # Verify again
                    arch=$(docker image inspect "$image" --format '{{.Architecture}}' 2>/dev/null)
                    if [ "$arch" = "amd64" ]; then
                        echo "  ✅ Successfully pulled AMD64 version using digest"
                        ((success++))
                    else
                        echo "  ❌ Still got $arch architecture"
                        ((failed++))
                    fi
                else
                    echo "  ❌ Failed to pull by digest"
                    ((failed++))
                fi
            else
                echo "  ❌ Could not find AMD64 digest in manifest"
                ((failed++))
            fi
        fi
    else
        echo "  ❌ Failed to pull image"
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
