#!/usr/bin/env bash
#
# build.sh
#
# Builds a distributable package of the game into mmbasic/dist/darnley/,
# copying in the data/ and images/ assets, obfuscating the data files so
# casual inspection doesn't trivially spoil the mystery, then zips the
# result into mmbasic/dist/darnley.zip.
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

echo "Copying from 'src/data/' to '$PKG_DIR/data/' ..."

cp -R data "$PKG_DIR/"
rm "$PKG_DIR/data/p_template_suspect.msg"
cp -R images "$PKG_DIR/"

# Obfuscate the copied data files in place. mmbasic/data/ (the source
# checked into git) is left completely untouched - only the copy inside
# $PKG_DIR/data is modified. Any Error raised by the tool (including its
# hard-fail safety check) propagates a non-zero exit under `set -euo
# pipefail` above, aborting the build.
#
# NOTE: the exact `mmbasic` invocation for running a script non-interactively
# and exiting (flags, if any) isn't pinned down elsewhere in this repo -
# this mirrors the `cd mmbasic/src && mmbasic darnley.bas` convention from
# CLAUDE.md, but should be confirmed/adjusted against how spupdate.bas is
# actually invoked in this environment before relying on it in CI.
( cd src && mmbasic obfuscate_build.bas "$SCRIPT_DIR/$PKG_DIR/data" )

# Transpile basic files
sptrans -e=1 -i=1 -n -s=1 -T -DNO_INCLUDE_GUARDS -DNO_EXTRA_CHECKS -DINLINE_CONSTANTS src/darnley.bas "$PKG_DIR/darnley.bas"

# Zip it up. -r recurse, -X drop extended attrs (cleaner cross-platform zip),
# -q quiet. Remove any previous zip first so `zip` doesn't just merge into it.
rm -f "$ZIP_FILE"
( cd "$DIST_DIR" && zip -rXq "$(basename "$ZIP_FILE")" "$(basename "$PKG_DIR")" )

echo "Done."
echo "  Package dir: $SCRIPT_DIR/$PKG_DIR"
echo "  Zip file:    $SCRIPT_DIR/$ZIP_FILE"
