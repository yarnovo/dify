#!/bin/bash

# Script to generate a pull script for linux/amd64 platform (CentOS deployment)
# Reads docker-compose.yaml and creates pull-all-images-linux-amd64.sh
# The generated script pulls all images for linux/amd64 architecture

# Parse command line arguments
# Default to linux/amd64 platform
PLATFORM="linux/amd64"
OUTPUT_SCRIPT="pull-all-images-linux-amd64.sh"

while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            OUTPUT_SCRIPT="pull-all-images-${2//\//-}.sh"
            shift 2
            ;;
        --output)
            OUTPUT_SCRIPT="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [--platform linux/amd64|linux/arm64] [--output filename.sh]"
            echo "Default: --platform linux/amd64"
            echo "Example: $0 --platform linux/arm64"
            exit 1
            ;;
    esac
done

# Input files
INPUT_FILE="docker-compose.yaml"
IGNORE_FILE="ignore-images.txt"

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
if [ -n "$PLATFORM" ]; then
    echo "Platform: $PLATFORM"
fi
echo ""

# Prepare header with platform info
PLATFORM_DESC=""
PLATFORM_CMD=""
if [ -n "$PLATFORM" ]; then
    PLATFORM_DESC=" ($PLATFORM platform)"
    PLATFORM_CMD=" --platform $PLATFORM"
fi

# Start writing the output script
cat > "$OUTPUT_SCRIPT" << HEADER
#!/bin/bash

# Auto-generated script to pull all Docker images from docker-compose.yaml
# Generated on: $(date)
# Platform: ${PLATFORM:-native}

echo "Starting to pull all Docker images${PLATFORM_DESC}..."
echo "=================================="
echo ""

# Counter for tracking progress
total=0
success=0
failed=0

# Function to pull an image with error handling and digest fallback
pull_image() {
    local image="\$1"
    local index="\$2"
    local total="\$3"

    echo "[\$index/\$total] Processing: \$image"

    # First, try to pull with --platform
    echo "  → Attempting to pull with --platform linux/amd64..."
    if docker pull --platform linux/amd64 "\$image"; then
        # Check if we actually got AMD64
        arch=\$(docker image inspect "\$image" --format '{{.Architecture}}' 2>/dev/null)

        if [ "\$arch" = "amd64" ] || [ "\$arch" = "x86_64" ]; then
            echo "  ✅ Successfully pulled AMD64 version"
            ((success++))
        else
            echo "  ⚠️  Got \$arch instead of amd64, trying digest method..."

            # Remove the wrong architecture version
            docker rmi "\$image" --force 2>/dev/null || true

            # Try to get AMD64 digest
            echo "  → Getting AMD64 digest from manifest..."
            amd64_digest=\$(docker manifest inspect "\$image" 2>/dev/null | jq -r '.manifests[] | select(.platform.architecture == "amd64") | .digest' | head -1)

            if [ -n "\$amd64_digest" ] && [ "\$amd64_digest" != "null" ]; then
                echo "  → Found digest: \$amd64_digest"

                # Extract base image name without tag
                if [[ "\$image" == *:* ]]; then
                    base_image="\${image%:*}"
                    tag="\${image#*:}"
                else
                    base_image="\$image"
                    tag="latest"
                fi

                # Pull by digest
                echo "  → Pulling by digest..."
                if docker pull "\${base_image}@\${amd64_digest}"; then
                    # Tag it properly
                    docker tag "\${base_image}@\${amd64_digest}" "\$image"

                    # Verify again
                    arch=\$(docker image inspect "\$image" --format '{{.Architecture}}' 2>/dev/null)
                    if [ "\$arch" = "amd64" ]; then
                        echo "  ✅ Successfully pulled AMD64 version using digest"
                        ((success++))
                    else
                        echo "  ❌ Still got \$arch architecture"
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

HEADER

# Replace the date in the header
sed -i.bak "s/\$(date)/$(date)/" "$OUTPUT_SCRIPT" && rm "$OUTPUT_SCRIPT.bak"

# Extract all unique images from docker-compose.yaml
# Use a temporary file to store unique images
temp_images=$(mktemp)

while IFS= read -r line; do
    # Check if the line contains "image:"
    if [[ "$line" =~ ^[[:space:]]*image:[[:space:]]*(.+)$ ]]; then
        image="${BASH_REMATCH[1]}"
        # Trim whitespace
        image=$(echo "$image" | xargs)

        # Check if image should be ignored
        if should_ignore "$image"; then
            echo "Skipping ignored image: $image"
            continue
        fi

        # Add to temporary file
        echo "$image" >> "$temp_images"
    fi
done < "$INPUT_FILE"

# Get unique images and store in array
images_array=()
while IFS= read -r image; do
    images_array+=("$image")
done < <(sort -u "$temp_images")

# Clean up temp file
rm -f "$temp_images"

# Images are already sorted from the sort -u command
sorted_images=("${images_array[@]}")

# Count total images
total_count=${#sorted_images[@]}

echo "Found $total_count unique images to pull"
echo ""

# Write pull commands to the output script
echo "# Pull all images" >> "$OUTPUT_SCRIPT"
echo "total=$total_count" >> "$OUTPUT_SCRIPT"
echo "" >> "$OUTPUT_SCRIPT"

index=1
for image in "${sorted_images[@]}"; do
    echo "pull_image \"$image\" $index \$total" >> "$OUTPUT_SCRIPT"
    echo "Image $index/$total_count: $image"
    ((index++))
done

# Add summary to the output script
cat >> "$OUTPUT_SCRIPT" << 'FOOTER'

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
FOOTER

# Make the generated script executable
chmod +x "$OUTPUT_SCRIPT"

echo ""
echo "✅ Successfully generated $OUTPUT_SCRIPT"
echo ""
echo "To pull all images, run:"
echo "  ./$OUTPUT_SCRIPT"
echo ""
echo "Or to run in background and log output:"
echo "  ./$OUTPUT_SCRIPT 2>&1 | tee pull-images.log"