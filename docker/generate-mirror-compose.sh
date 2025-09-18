#!/bin/bash

# Script to read docker-compose.yaml and create a new file with updated image references
# Converts all images to use registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors/
# Replaces / in image names with - (e.g., langgenius/dify-api becomes langgenius-dify-api)

# Input and output files
INPUT_FILE="docker-compose.yaml"
OUTPUT_FILE="docker-compose-mirror.yaml"

# Check if docker-compose.yaml exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found in current directory"
    exit 1
fi

echo "Reading from: $INPUT_FILE"
echo "Writing to: $OUTPUT_FILE"
echo ""

# Function to transform image name
transform_image() {
    local image="$1"

    # Extract image name and tag
    if [[ "$image" =~ ^(.+):(.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        tag="${BASH_REMATCH[2]}"
    else
        name="$image"
        tag="latest"
    fi

    # Remove any existing registry prefix (like quay.io/, ghcr.io/, docker.elastic.co/, etc.)
    # This handles various registry formats
    if [[ "$name" =~ ^([^/]+\.[^/]+)/(.+)$ ]]; then
        # Has a registry prefix (contains . before first /)
        name="${BASH_REMATCH[2]}"
    fi

    # Replace all / with - in the image name
    name=$(echo "$name" | sed 's|/|-|g')

    # Return the transformed image
    echo "registry.cn-heyuan.aliyuncs.com/yarnb-docker-mirrors/${name}:${tag}"
}

# Clear the output file if it exists
> "$OUTPUT_FILE"

# Process the file line by line
while IFS= read -r line; do
    # Check if the line contains "image:"
    if [[ "$line" =~ ^([[:space:]]*)image:[[:space:]]*(.+)$ ]]; then
        indent="${BASH_REMATCH[1]}"
        original_image="${BASH_REMATCH[2]}"

        # Transform the image name
        new_image=$(transform_image "$original_image")

        # Write the modified line to the new file
        echo "${indent}image: ${new_image}" >> "$OUTPUT_FILE"

        # Log the change
        echo "Transformed: $original_image"
        echo "         -> $new_image"
        echo ""
    else
        # Write the line as-is to the new file
        echo "$line" >> "$OUTPUT_FILE"
    fi
done < "$INPUT_FILE"

echo "✅ Successfully created $OUTPUT_FILE with updated Docker images"
echo ""
echo "To use the new configuration:"
echo "  docker-compose -f $OUTPUT_FILE up -d"