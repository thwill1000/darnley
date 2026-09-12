#!/usr/bin/env bash
#
# build.sh
#
# Builds a distributable package of the game into mmbasic/dist/darnley/,
# copying in the data/ and images/ assets, then zips the result into
# mmbasic/dist/darnley.zip.
#
# Run from anywhere; paths are resolved relative to this script's location
# (which is expected to be the mmbasic/ directory).

set -euo pipefail

# Resolve the directory this script lives in (mmbasic/), regardless of cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DIST_DIR="dist"
PKG_DIR="$DIST_DIR/darnley"
ZIP_FILE="$DIST_DIR/darnley.zip"

echo "Building distribution in $SCRIPT_DIR/$PKG_DIR ..."

# Start clean so stale files from previous builds don't linger.
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"
mkdir -p "$PKG_DIR/saves"
mkdir -p "$PKG_DIR/scripts"

# Sanity check the expected source directories exist before copying.
for d in data images; do
  if [ ! -d "$d" ]; then
    echo "ERROR: expected directory '$d' not found in $SCRIPT_DIR" >&2
    exit 1
  fi
done

cp -R data "$PKG_DIR/"
rm "$PKG_DIR/data/p_template_suspect.msg"
cp -R images "$PKG_DIR/"

# Transpile basic files
sptrans -e=1 -i=1 -n -s=1 -T -DNO_INCLUDE_GUARDS -DNO_EXTRA_CHECKS -DINLINE_CONSTANTS src/darnley.bas "$PKG_DIR/darnley.bas"

# Zip it up. -r recurse, -X drop extended attrs (cleaner cross-platform zip),
# -q quiet. Remove any previous zip first so `zip` doesn't just merge into it.
rm -f "$ZIP_FILE"
( cd "$DIST_DIR" && zip -rXq "$(basename "$ZIP_FILE")" "$(basename "$PKG_DIR")" )

echo "Done."
echo "  Package dir: $SCRIPT_DIR/$PKG_DIR"
echo "  Zip file:    $SCRIPT_DIR/$ZIP_FILE"
