#!/usr/bin/env bash

PATCHES_DIR=$(pwd)/../patches
mkdir -p "$PATCHES_DIR"

for d in FFmpeg_*; do
    [[ ! -d "$d" ]] && continue

    echo "Processing directory: $d"

    # Extract suffix (51 -> 5.1, etc.)
    suffix="${d#FFmpeg_}"
    major="${suffix:0:1}"
    minor="${suffix:1:1}"
    ARCANA_PATCH_VERSION="${major}.${minor}"

    # Go into the top-level folder only
    cd "$d" || {
        echo "Could not cd into directory $d. Skipping."
        continue
    }

    # Create a date+uuid file
    echo "$(date) $(uuidgen)" > Arcana_Patch_Date.md

    # Stage changes
    git add -u
    git add Arcana_Patch_Date.md libavutil/toml-c.h 2>/dev/null

    # Create patch
    PATCH_FILENAME="ffmpeg_arcana_patch_${ARCANA_PATCH_VERSION}.patch"
    git diff --cached > "$PATCH_FILENAME"

    # Move patch out
    mv "$PATCH_FILENAME" "$PATCHES_DIR" 2>/dev/null || {
        echo "Warning: Could not move patch $PATCH_FILENAME to $PATCHES_DIR."
    }

    # Unstage changes
    git restore --staged .

    cd ..
    echo "Done creating patch for $d."
    echo "-----------------------------------"
done

echo "All available FFmpeg_* directories processed."
