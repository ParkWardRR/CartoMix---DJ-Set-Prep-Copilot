#!/bin/bash
# CartoMix - Generate Hero Animation from Screenshots
# Creates an animated GIF slideshow of key features

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENS_DIR="$PROJECT_DIR/docs/assets/screens"
OUTPUT_DIR="$PROJECT_DIR/docs/assets/video"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}CartoMix Hero Animation Generator${NC}"
echo "==================================="

# Check dependencies - use magick for ImageMagick v7
if command -v magick &> /dev/null; then
    IM_CMD="magick"
elif command -v convert &> /dev/null; then
    IM_CMD="convert"
else
    echo "ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Key screenshots for the hero animation (in order)
HERO_SCREENS=(
    "waveform-painting"
    "transition-detection"
    "energy-matching"
    "track-analysis"
    "library-view"
    "set-builder"
)

echo -e "\n${YELLOW}Converting screenshots to PNG...${NC}"
TEMP_DIR=$(mktemp -d)

for i in "${!HERO_SCREENS[@]}"; do
    name="${HERO_SCREENS[$i]}"
    src="$SCREENS_DIR/${name}.webp"

    if [ -f "$src" ]; then
        # Convert to PNG and add sequence number
        $IM_CMD "$src" -resize 1280x800 "$TEMP_DIR/frame_$(printf "%02d" $i).png"
        echo "  Prepared: $name"
    else
        echo "  Warning: $name not found"
    fi
done

echo -e "\n${YELLOW}Generating animated GIF (2s per frame)...${NC}"
$IM_CMD -delay 200 -loop 0 "$TEMP_DIR/frame_*.png" "$OUTPUT_DIR/cartomix-hero.gif"
echo "  Created: cartomix-hero.gif"

# Optional: Generate MP4 if ffmpeg available
if command -v ffmpeg &> /dev/null; then
    echo -e "\n${YELLOW}Generating MP4 video...${NC}"
    ffmpeg -y -framerate 0.5 -pattern_type glob -i "$TEMP_DIR/frame_*.png" \
        -c:v libx264 -pix_fmt yuv420p -crf 23 \
        -vf "fps=30,scale=1280:-2" \
        "$OUTPUT_DIR/cartomix-hero.mp4" 2>/dev/null || echo "  MP4 generation skipped"
    [ -f "$OUTPUT_DIR/cartomix-hero.mp4" ] && echo "  Created: cartomix-hero.mp4"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}Hero animation generation complete!${NC}"
echo "Output files:"
ls -lh "$OUTPUT_DIR"/cartomix-hero.* 2>/dev/null || true

echo -e "\n${YELLOW}To use in README:${NC}"
echo '![CartoMix](docs/assets/video/cartomix-hero.gif)'
