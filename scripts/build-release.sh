#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     CartoMix Release Build Script                             ║
# ║                                                                               ║
# ║  Automates the complete macOS release pipeline:                               ║
# ║  Test → Build → Sign App → Create DMG → Sign DMG → Notarize → Staple → Verify ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# WHAT THIS SCRIPT DOES:
# ----------------------
# 1. Runs Flutter tests to ensure code quality
# 2. Builds a release version of the macOS app
# 3. Signs the .app bundle with Developer ID (enables Gatekeeper trust)
# 4. Creates a compressed DMG disk image (UDBZ format)
# 5. Signs the DMG itself (required for notarization)
# 6. Submits to Apple's notarization service (malware scan)
# 7. Staples the notarization ticket (offline verification)
# 8. Verifies the final DMG passes Gatekeeper
#
# The result is a DMG that opens without ANY macOS security warnings.
#
# USAGE:
# ------
#   ./scripts/build-release.sh [version]    Build with specific version
#   ./scripts/build-release.sh              Use version from pubspec.yaml
#   ./scripts/build-release.sh --help       Show this help message
#
# EXAMPLES:
# ---------
#   ./scripts/build-release.sh 0.15.0       Build v0.15.0 release
#   ./scripts/build-release.sh              Build using pubspec.yaml version
#
# PREREQUISITES:
# --------------
# 1. Developer ID Application certificate installed in Keychain
#    - Get one from https://developer.apple.com/account/resources/certificates
#    - Must be "Developer ID Application" (not Mac App Store)
#
# 2. Notarization credentials stored in Keychain:
#    xcrun notarytool store-credentials "notary-api" \
#      --apple-id "your@email.com" \
#      --team-id "TEAM_ID" \
#      --password "app-specific-password"
#
# 3. Flutter SDK installed and in PATH
#
# 4. Xcode Command Line Tools installed
#
# OUTPUT:
# -------
# Creates: CartoMix-v{VERSION}.dmg in the project root
# - Signed with Developer ID
# - Notarized by Apple
# - Stapled for offline verification
# - Verified to pass Gatekeeper
#
# TROUBLESHOOTING:
# ----------------
# - "No signing identity found": Install Developer ID cert in Keychain Access
# - "Notarization failed": Run notarytool log for details (shown in error)
# - "Stapling failed": DMG may already be stapled, or notarization incomplete
# - Tests failing: Fix tests before release, or use --skip-tests (not recommended)
#
# For more info: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Show help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo -e "${CYAN}CartoMix Release Build Script${NC}"
    echo ""
    echo "Automates the complete macOS release pipeline with code signing and notarization."
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./scripts/build-release.sh [version]    Build with specific version"
    echo "  ./scripts/build-release.sh              Use version from pubspec.yaml"
    echo "  ./scripts/build-release.sh --help       Show this help"
    echo ""
    echo -e "${YELLOW}Pipeline Steps:${NC}"
    echo "  1. Run Flutter tests"
    echo "  2. Build macOS release (flutter build macos --release)"
    echo "  3. Sign app bundle (codesign --deep --force --options runtime)"
    echo "  4. Create DMG (hdiutil create -format UDBZ)"
    echo "  5. Sign DMG (codesign --sign)"
    echo "  6. Notarize (xcrun notarytool submit --wait)"
    echo "  7. Staple ticket (xcrun stapler staple)"
    echo "  8. Verify Gatekeeper (spctl -a -vvv -t install)"
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  - Developer ID Application certificate in Keychain"
    echo "  - Notarization credentials: xcrun notarytool store-credentials \"notary-api\""
    echo "  - Flutter SDK installed"
    echo ""
    echo -e "${YELLOW}Output:${NC}"
    echo "  CartoMix-v{VERSION}.dmg - Signed, notarized, and ready for distribution"
    echo ""
    exit 0
fi

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
