#!/bin/bash
# CartoMix - Generate Hero Animation (Animated WebP)
# Creates a fast-paced, dynamic showcase of key features

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENS_DIR="$PROJECT_DIR/docs/assets/screens"
OUTPUT_DIR="$PROJECT_DIR/docs/assets/video"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   CartoMix Hero Animation Generator${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

mkdir -p "$OUTPUT_DIR"

# Hero screens in dynamic order (most impressive first)
HERO_SCREENS=(
    "waveform-painting"
    "transition-detection"
    "track-analysis"
    "energy-matching"
    "section-embeddings"
    "set-builder"
    "graph-view"
    "audio-playback"
    "library-view"
    "user-overrides"
)

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "\n${YELLOW}Preparing frames...${NC}"

# Use ImageMagick for animated WebP (more reliable)
if command -v magick &> /dev/null; then
    IM_CMD="magick"
elif command -v convert &> /dev/null; then
    IM_CMD="convert"
else
    echo "ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

# Prepare frames
frame_files=()
for name in "${HERO_SCREENS[@]}"; do
    src="$SCREENS_DIR/${name}.webp"
    if [ -f "$src" ]; then
        # Convert to PNG for processing
        out="$TEMP_DIR/${name}.png"
        $IM_CMD "$src" -resize 1280x800 "$out"
        frame_files+=("$out")
        echo -e "  ${GREEN}✓${NC} $name"
    else
        echo -e "  ${YELLOW}!${NC} $name (not found)"
    fi
done

echo -e "\n${CYAN}Total: ${#frame_files[@]} screens${NC}"

# Generate animated WebP with img2webp (part of libwebp)
echo -e "\n${YELLOW}Generating animated WebP...${NC}"

if command -v img2webp &> /dev/null; then
    # Build arguments: 800ms delay per frame, lossy, quality 85
    args=(-loop 0)
    for f in "${frame_files[@]}"; do
        args+=(-d 800 -lossy -q 85 "$f")
    done
    args+=(-o "$OUTPUT_DIR/cartomix-hero.webp")

    img2webp "${args[@]}"

    if [ -f "$OUTPUT_DIR/cartomix-hero.webp" ]; then
        size=$(ls -lh "$OUTPUT_DIR/cartomix-hero.webp" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} Created: cartomix-hero.webp ($size)"
    fi
else
    # Fallback: Use ImageMagick to create animated WebP
    echo "  Using ImageMagick fallback..."
    $IM_CMD -delay 80 -loop 0 "${frame_files[@]}" "$OUTPUT_DIR/cartomix-hero.webp"

    if [ -f "$OUTPUT_DIR/cartomix-hero.webp" ]; then
        size=$(ls -lh "$OUTPUT_DIR/cartomix-hero.webp" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} Created: cartomix-hero.webp ($size)"
    fi
fi

# Generate MP4 for social media / fallback
echo -e "\n${YELLOW}Generating MP4 fallback...${NC}"

if command -v ffmpeg &> /dev/null; then
    # Create input file list for ffmpeg
    echo "ffconcat version 1.0" > "$TEMP_DIR/input.txt"
    for f in "${frame_files[@]}"; do
        echo "file '$f'" >> "$TEMP_DIR/input.txt"
        echo "duration 0.8" >> "$TEMP_DIR/input.txt"
    done
    # Repeat last frame
    last_idx=$((${#frame_files[@]} - 1))
    echo "file '${frame_files[$last_idx]}'" >> "$TEMP_DIR/input.txt"

    ffmpeg -y -f concat -safe 0 -i "$TEMP_DIR/input.txt" \
        -c:v libx264 -pix_fmt yuv420p -crf 20 \
        -vf "scale=1280:-2:flags=lanczos" \
        -movflags +faststart \
        "$OUTPUT_DIR/cartomix-hero.mp4" 2>/dev/null

    if [ -f "$OUTPUT_DIR/cartomix-hero.mp4" ]; then
        size=$(ls -lh "$OUTPUT_DIR/cartomix-hero.mp4" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} Created: cartomix-hero.mp4 ($size)"
    fi
fi

# Remove old GIF if exists
rm -f "$OUTPUT_DIR/cartomix-hero.gif"

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Hero animation complete!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
ls -lh "$OUTPUT_DIR"/cartomix-hero.* 2>/dev/null || echo "No output files found"
echo ""
echo -e "${YELLOW}README usage:${NC}"
echo '![CartoMix](docs/assets/video/cartomix-hero.webp)'
