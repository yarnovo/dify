#!/bin/bash

# Script to generate a push script for Aliyun Container Registry
# Reads docker-compose.yaml and creates push-to-aliyun-registry.sh
# The generated script pushes linux/amd64 images to registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors

# Configuration
REGISTRY="registry.cn-heyuan.aliyuncs.com"
NAMESPACE="yarnb-docker-mirrors"
INPUT_FILE="docker-compose.yaml"
IGNORE_FILE="ignore-images.txt"
OUTPUT_SCRIPT="push-to-aliyun-registry.sh"

# Check if docker-compose.yaml exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found in current directory"
    exit 1
fi

# Load ignore list if exists
declare -a ignore_patterns=()
if [ -f "$IGNORE_FILE" ]; then
    echo "Loading ignore list from: $IGNORE_FILE"
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            line=$(echo "$line" | xargs)  # Trim whitespace
            ignore_patterns+=("$line")
            echo "  Ignoring: $line"
        fi
    done < "$IGNORE_FILE"
    echo ""
fi

# Function to check if an image should be ignored
should_ignore() {
    local image="$1"
    for pattern in "${ignore_patterns[@]}"; do
        # Support wildcard matching
        if [[ "$image" == $pattern || "$image" == $pattern* ]]; then
            return 0  # Should ignore
        fi
    done
    return 1  # Should not ignore
}

echo "Reading from: $INPUT_FILE"
echo "Generating script: $OUTPUT_SCRIPT"
echo "Target registry: $REGISTRY/$NAMESPACE"
echo ""

# Start writing the output script
cat > "$OUTPUT_SCRIPT" << HEADER
#!/bin/bash

# Auto-generated script to push Docker images to Aliyun Container Registry
# Generated on: $(date)
# Target registry: $REGISTRY/$NAMESPACE
# Platform: linux/amd64 (for CentOS deployment)

REGISTRY="$REGISTRY"
NAMESPACE="$NAMESPACE"

echo "Starting to push Docker images to \$REGISTRY/\$NAMESPACE"
echo "============================================================"
echo ""

# Check if logged in to registry
echo "Checking registry login status..."
if ! docker pull \$REGISTRY/\$NAMESPACE/test:latest >/dev/null 2>&1; then
    if [ "\$?" -ne "1" ]; then
        echo "⚠️  Warning: May not be logged in to \$REGISTRY"
        echo "   If push fails, please run: docker login \$REGISTRY"
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
    local original_image="\$1"
    local index="\$2"
    local total_count="\$3"

    echo "[\$index/\$total_count] Processing: \$original_image"

    # Extract image name and tag
    if [[ "\$original_image" =~ ^(.+):(.+)\$ ]]; then
        name="\${BASH_REMATCH[1]}"
        tag="\${BASH_REMATCH[2]}"
    else
        name="\$original_image"
        tag="latest"
    fi

    # Remove any existing registry prefix
    if [[ "\$name" =~ ^([^/]+\\.[^/]+)/(.+)\$ ]]; then
        name="\${BASH_REMATCH[2]}"
    fi

    # Replace all / with - in the image name
    clean_name=\$(echo "\$name" | sed 's|/|-|g')

    # Construct target image name
    target_image="\$REGISTRY/\$NAMESPACE/\${clean_name}:\${tag}"

    # Check if the original image exists locally
    if ! docker image inspect "\$original_image" >/dev/null 2>&1; then
        echo "  ⚠️  Image not found locally: \$original_image"
        echo "     Skipping (run pull-all-images-linux-amd64.sh first)"
        ((skipped++))
        echo ""
        return
    fi

    # Tag the image
    echo "  → Tagging as: \$target_image"
    if ! docker tag "\$original_image" "\$target_image"; then
        echo "  ❌ Failed to tag: \$original_image"
        ((failed++))
        echo ""
        return
    fi

    # Push the image
    echo "  → Pushing to registry..."
    if docker push "\$target_image"; then
        echo "  ✅ Successfully pushed: \$target_image"
        ((success++))
    else
        echo "  ❌ Failed to push: \$target_image"
        ((failed++))
    fi

    echo ""
}

# Pull all images
total=TOTAL_COUNT_PLACEHOLDER

HEADER

# Extract unique images from docker-compose.yaml
temp_images=$(mktemp)

while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*image:[[:space:]]*(.+)$ ]]; then
        image="${BASH_REMATCH[1]}"
        image=$(echo "$image" | xargs)

        # Check if image should be ignored
        if should_ignore "$image"; then
            echo "Skipping ignored image: $image"
            continue
        fi

        echo "$image" >> "$temp_images"
    fi
done < "$INPUT_FILE"

# Get unique images and store in array
images_array=()
while IFS= read -r image; do
    images_array+=("$image")
done < <(sort -u "$temp_images")

rm -f "$temp_images"

# Count total images
total_count=${#images_array[@]}

echo "Found $total_count unique images to push"
echo ""

# Replace the placeholder with actual count
sed -i.bak "s/TOTAL_COUNT_PLACEHOLDER/$total_count/" "$OUTPUT_SCRIPT" && rm "$OUTPUT_SCRIPT.bak"

# Write push commands to the output script
index=1
for image in "${images_array[@]}"; do
    echo "push_image \"$image\" $index \$total" >> "$OUTPUT_SCRIPT"
    echo "Image $index/$total_count: $image"
    ((index++))
done

# Add summary to the output script
cat >> "$OUTPUT_SCRIPT" << 'FOOTER'

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
FOOTER

# Make the generated script executable
chmod +x "$OUTPUT_SCRIPT"

echo ""
echo "✅ Successfully generated $OUTPUT_SCRIPT"
echo ""
echo "Workflow:"
echo "  1. Pull images:  ./pull-all-images-linux-amd64.sh"
echo "  2. Push images:  ./$OUTPUT_SCRIPT"
echo ""
echo "Images will be available at:"
echo "  $REGISTRY/$NAMESPACE/"