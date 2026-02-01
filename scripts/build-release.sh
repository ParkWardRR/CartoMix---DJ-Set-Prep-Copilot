#!/bin/bash
# CartoMix Release Build Script
# Builds, signs, notarizes, and staples the macOS DMG
#
# Usage: ./scripts/build-release.sh [version]
# Example: ./scripts/build-release.sh 0.13.0
#
# Prerequisites:
# - Developer ID Application certificate installed
# - Notarization credentials stored: xcrun notarytool store-credentials "notary-api"
# - Flutter SDK installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SIGNING_IDENTITY="Developer ID Application: Twesh Deshetty (6U62M4232W)"
NOTARY_PROFILE="notary-api"
APP_NAME="cartomix_flutter"
FLUTTER_DIR="cartomix_flutter"

# Get version from argument or pubspec.yaml
if [ -n "$1" ]; then
    VERSION="$1"
else
    VERSION=$(grep '^version:' "$FLUTTER_DIR/pubspec.yaml" | sed 's/version: //' | sed 's/+.*//')
fi

DMG_NAME="CartoMix-v${VERSION}.dmg"
APP_PATH="$FLUTTER_DIR/build/macos/Build/Products/Release/${APP_NAME}.app"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       CartoMix Release Build Script v1.0                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Version:${NC} v${VERSION}"
echo -e "${YELLOW}DMG Name:${NC} ${DMG_NAME}"
echo ""

# Step 1: Run tests
echo -e "${BLUE}[1/7]${NC} Running Flutter tests..."
cd "$FLUTTER_DIR"
if flutter test; then
    echo -e "${GREEN}✓ All tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed. Aborting.${NC}"
    exit 1
fi
cd ..

# Step 2: Build release
echo ""
echo -e "${BLUE}[2/7]${NC} Building macOS release..."
cd "$FLUTTER_DIR"
if flutter build macos --release; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed. Aborting.${NC}"
    exit 1
fi
cd ..

# Step 3: Sign the app
echo ""
echo -e "${BLUE}[3/7]${NC} Signing app with Developer ID..."
if codesign --deep --force --options runtime --sign "$SIGNING_IDENTITY" "$APP_PATH"; then
    echo -e "${GREEN}✓ App signed${NC}"
else
    echo -e "${RED}✗ Signing failed. Check your certificate.${NC}"
    exit 1
fi

# Step 4: Create DMG
echo ""
echo -e "${BLUE}[4/7]${NC} Creating DMG..."
rm -f "$DMG_NAME"
if hdiutil create -volname "CartoMix v${VERSION}" -srcfolder "$APP_PATH" -ov -format UDBZ "$DMG_NAME"; then
    echo -e "${GREEN}✓ DMG created${NC}"
else
    echo -e "${RED}✗ DMG creation failed.${NC}"
    exit 1
fi

# Step 5: Sign the DMG
echo ""
echo -e "${BLUE}[5/7]${NC} Signing DMG..."
if codesign --sign "$SIGNING_IDENTITY" "$DMG_NAME"; then
    echo -e "${GREEN}✓ DMG signed${NC}"
else
    echo -e "${RED}✗ DMG signing failed.${NC}"
    exit 1
fi

# Step 6: Notarize
echo ""
echo -e "${BLUE}[6/7]${NC} Submitting for notarization (this may take a few minutes)..."
if xcrun notarytool submit "$DMG_NAME" --keychain-profile "$NOTARY_PROFILE" --wait; then
    echo -e "${GREEN}✓ Notarization accepted${NC}"
else
    echo -e "${RED}✗ Notarization failed.${NC}"
    echo -e "${YELLOW}Tip: Run 'xcrun notarytool log <submission-id> --keychain-profile $NOTARY_PROFILE' for details${NC}"
    exit 1
fi

# Step 7: Staple
echo ""
echo -e "${BLUE}[7/7]${NC} Stapling notarization ticket..."
if xcrun stapler staple "$DMG_NAME"; then
    echo -e "${GREEN}✓ Stapling successful${NC}"
else
    echo -e "${RED}✗ Stapling failed.${NC}"
    exit 1
fi

# Verify
echo ""
echo -e "${BLUE}Verifying...${NC}"
VERIFY_OUTPUT=$(spctl -a -vvv -t install "$DMG_NAME" 2>&1)
if echo "$VERIFY_OUTPUT" | grep -q "accepted"; then
    echo -e "${GREEN}✓ Verification passed: Notarized Developer ID${NC}"
else
    echo -e "${RED}✗ Verification failed${NC}"
    echo "$VERIFY_OUTPUT"
    exit 1
fi

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    BUILD COMPLETE!                       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Output:${NC} ${DMG_NAME}"
echo -e "${YELLOW}Size:${NC} $(du -h "$DMG_NAME" | cut -f1)"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Test the DMG by opening it"
echo "  2. Create GitHub release: gh release create v${VERSION} ${DMG_NAME} --title \"v${VERSION}\""
echo "  3. Update README and roadmap"
echo ""
