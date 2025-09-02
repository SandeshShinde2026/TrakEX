#!/bin/bash

# This script will help you save the logo image to the correct location
# You need to manually save the image from the chat to a temporary location
# Then run this script with the path to the saved image

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_saved_image>"
    exit 1
fi

SOURCE_IMAGE="$1"
TARGET_DIR="assets/images"
TARGET_FILE="$TARGET_DIR/mf_logo.png"

# Ensure the target directory exists
mkdir -p "$TARGET_DIR"

# Copy the image to the target location
cp "$SOURCE_IMAGE" "$TARGET_FILE"

echo "Image copied to $TARGET_FILE"
echo "Now you can run: flutter pub get && flutter pub run flutter_launcher_icons"
