#!/bin/bash

# Usage: convert-images.sh [--web]
#   (default)  240x160 / 320x240 JPEGs into mmbasic/images
#   --web      aspect-preserving WebP, at most 960px wide, into ../web/images

cd "$(dirname "$0")" || exit 1

MODE="mmbasic"
case "$1" in
    "") ;;
    "--web") MODE="web" ;;
    *) echo "Usage: $0 [--web]"; exit 1 ;;
esac

# Define source and destination directories
SRC_DIR="src-graphics/images"
if [ "$MODE" = "web" ]; then
    DEST_DIR="../web/images"
    EXT="webp"
else
    DEST_DIR="images"
    EXT="jpg"
fi

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
    dest_file="$DEST_DIR/${filename}.${EXT}"
    
    if [ "$MODE" = "web" ]; then
        case "$filename" in
            "END_SCREEN"|"SPLASH_SCREEN")
                # Source aspect ratio differs from the other location images,
                # so force a non-aspect-preserving resize to the same output
                # size as the other images (3:2, matching .transcript-image's
                # CSS aspect-ratio) to avoid letterboxing in the web UI.
                WEB_DIMENSIONS="960x644!"
                ;;
            *)
                WEB_DIMENSIONS="960x960>"
                ;;
        esac
        convert "$src_file" -resize "$WEB_DIMENSIONS" -quality 80 "$dest_file"
        echo "Converted: $filename.png -> ${filename}.${EXT}"
        ((count++))
        continue
    fi

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
    
    echo "Converted: $filename.png -> ${filename}.${EXT} (${DIMENSIONS%!})"
    ((count++))
done

if [ "$count" -eq 0 ]; then
    echo "No .png files found in '$SRC_DIR'."
else
    echo "Successfully converted $count image(s)."
fi
