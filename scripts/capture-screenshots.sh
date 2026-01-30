#!/bin/bash
# CartoMix - Automated Screenshot Capture Script
# Builds the app, launches it, and captures screenshots of each view

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/docs/assets/screens"
APP_NAME="Dardania"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}CartoMix Screenshot Automation${NC}"
echo "================================"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build release version
echo -e "\n${YELLOW}Building release version...${NC}"
cd "$PROJECT_DIR"
swift build -c release

# Get path to built executable
APP_PATH="$PROJECT_DIR/.build/release/$APP_NAME"

if [ ! -f "$APP_PATH" ]; then
    echo -e "${RED}Error: Could not find built app at $APP_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Function to capture a screenshot
capture_screenshot() {
    local name="$1"
    local delay="${2:-2}"

    echo -e "  Capturing: $name"
    sleep "$delay"

    # Get the window ID of Dardania
    local wid
    wid=$(osascript -e "tell application \"System Events\" to tell process \"$APP_NAME\" to get id of window 1" 2>/dev/null || echo "")

    if [ -z "$wid" ]; then
        # Fallback: capture the frontmost window
        screencapture -o -x "$OUTPUT_DIR/${name}.png"
    else
        screencapture -l "$wid" -o -x "$OUTPUT_DIR/${name}.png"
    fi

    # Convert to WebP
    if command -v cwebp &> /dev/null; then
        cwebp -q 90 "$OUTPUT_DIR/${name}.png" -o "$OUTPUT_DIR/${name}.webp" 2>/dev/null
        rm "$OUTPUT_DIR/${name}.png"
        echo -e "    ${GREEN}✓${NC} Saved ${name}.webp"
    else
        echo -e "    ${YELLOW}!${NC} Saved ${name}.png (cwebp not installed for WebP conversion)"
    fi
}

# Function to send keystrokes
send_keystroke() {
    local key="$1"
    local modifiers="${2:-}"

    if [ -n "$modifiers" ]; then
        osascript -e "tell application \"System Events\" to keystroke \"$key\" using $modifiers"
    else
        osascript -e "tell application \"System Events\" to keystroke \"$key\""
    fi
}

# Function to click menu item
click_menu() {
    local menu="$1"
    local item="$2"

    osascript -e "
        tell application \"System Events\"
            tell process \"$APP_NAME\"
                click menu item \"$item\" of menu \"$menu\" of menu bar 1
            end tell
        end tell
    "
}

# Launch the app
echo -e "\n${YELLOW}Launching CartoMix...${NC}"
"$APP_PATH" &
APP_PID=$!

# Wait for app to fully launch
sleep 3

# Bring app to front
osascript -e "tell application \"$APP_NAME\" to activate" 2>/dev/null || \
    osascript -e "tell application \"System Events\" to set frontmost of process \"$APP_NAME\" to true"

echo -e "\n${YELLOW}Capturing screenshots...${NC}"

# 1. Library View (default view)
capture_screenshot "library-view" 2

# 2. Set Builder View (Cmd+2)
echo "  Switching to Set Builder..."
send_keystroke "2" "command down"
capture_screenshot "set-builder" 2

# 3. Graph View (Cmd+3)
echo "  Switching to Graph View..."
send_keystroke "3" "command down"
capture_screenshot "graph-view" 2

# 4. Back to Library for track selection (Cmd+1)
echo "  Switching back to Library..."
send_keystroke "1" "command down"
sleep 1

# 5. Track Analysis (select first track if available)
echo "  Attempting to select a track..."
osascript -e "
    tell application \"System Events\"
        tell process \"$APP_NAME\"
            # Try to click on the first item in the list
            try
                click row 1 of table 1 of scroll area 1 of window 1
            end try
        end tell
    end tell
" 2>/dev/null || true
capture_screenshot "track-analysis" 2

# 6. Try to capture waveform view if track is selected
echo "  Capturing waveform view..."
capture_screenshot "waveform-painting" 1

# 7. User Overrides panel
capture_screenshot "user-overrides" 1

# 8. Audio Playback (same view with playhead)
capture_screenshot "audio-playback" 1

# 9. Transition Detection view
capture_screenshot "transition-detection" 1

# 10. Energy Matching view
capture_screenshot "energy-matching" 1

# 11. Section Embeddings view
capture_screenshot "section-embeddings" 1

# Cleanup - quit the app
echo -e "\n${YELLOW}Cleaning up...${NC}"
osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || kill $APP_PID 2>/dev/null || true

echo -e "\n${GREEN}Screenshot capture complete!${NC}"
echo "Screenshots saved to: $OUTPUT_DIR"
echo ""
ls -la "$OUTPUT_DIR"
