#!/bin/bash

# Define source and destination directories
SRC_DIR="src-graphics/images"
DEST_DIR="images"

# Ensure the source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory '$SRC_DIR' does not exist."
    exit 1
fi

# Create destination directory if needed
mkdir -p "$DEST_DIR"

# Enable nullglob so the loop won't run if no .png files exist
shopt -s nullglob

count=0

for src_file in "$SRC_DIR"/*.png; do
    # Extract filename without path and extension
    filename=$(basename "$src_file" .png)
    dest_file="$DEST_DIR/${filename}.jpg"
    
    # Determine target dimensions based on filename
    case "$filename" in
        "END_SCREEN"|"SPLASH_SCREEN")
            DIMENSIONS="320x240!"
            ;;
        *)
            DIMENSIONS="240x160!"
            ;;
    esac

    # Convert and resize image
    convert "$src_file" -resize "$DIMENSIONS" "$dest_file"
    
    echo "Converted: $filename.png -> ${filename}.jpg (${DIMENSIONS%!})"
    ((count++))
done

if [ "$count" -eq 0 ]; then
    echo "No .png files found in '$SRC_DIR'."
else
    echo "Successfully converted $count image(s)."
fi
