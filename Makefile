# CartoMix - 100% macOS Native DJ Set Prep Copilot (Codename: Dardania)
# Build and test commands

.PHONY: all build build-release test test-core test-golden test-xpc clean lint format run help screenshots

# Default target
all: build

# Build debug
build:
	swift build

# Build release
build-release:
	swift build -c release

# Run all tests
test: test-core test-golden test-xpc
	@echo "All tests passed!"

# Run core library tests
test-core:
	swift test --filter DardaniaCoreTests

# Run golden export tests
test-golden:
	swift test --filter GoldenTests

# Run XPC tests
test-xpc:
	swift test --filter AnalyzerXPCTests

# Run app (debug)
run:
	swift run Dardania

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Lint Swift code
lint:
	swiftlint lint --strict

# Format Swift code
format:
	swiftformat Sources Tests --swiftversion 6.0

# Generate Xcode project
xcode:
	swift package generate-xcodeproj

# Build for release and archive
archive:
	mkdir -p build
	swift build -c release
	cp -R .build/release/Dardania build/
	@echo "Archive complete: build/Dardania"

# Run tests with coverage
test-coverage:
	swift test --enable-code-coverage
	xcrun llvm-cov report .build/debug/DardaniaPackageTests.xctest/Contents/MacOS/DardaniaPackageTests \
		-instr-profile=.build/debug/codecov/default.profdata

# Generate screenshots for documentation (programmatic)
screenshots:
	@echo "Generating screenshots programmatically..."
	@mkdir -p docs/assets/screens
	swift run Dardania -- --screenshots

# Generate screenshots using window capture (requires display)
screenshots-capture:
	@echo "Generating screenshots via window capture..."
	@mkdir -p docs/assets/screens
	@chmod +x scripts/capture-screenshots.sh
	@./scripts/capture-screenshots.sh

# Print help
help:
	@echo "CartoMix - 100% macOS Native DJ Set Prep Copilot (Codename: Dardania)"
	@echo ""
	@echo "Available targets:"
	@echo "  build          Build debug version"
	@echo "  build-release  Build release version"
	@echo "  test           Run all tests"
	@echo "  test-core      Run core library tests"
	@echo "  test-golden    Run golden export tests"
	@echo "  test-xpc       Run XPC service tests"
	@echo "  run            Run the app (debug)"
	@echo "  clean          Clean build artifacts"
	@echo "  lint           Lint Swift code"
	@echo "  format         Format Swift code"
	@echo "  xcode          Generate Xcode project"
	@echo "  archive        Build release archive"
	@echo "  test-coverage  Run tests with coverage report"
	@echo "  screenshots    Generate screenshots for docs"
	@echo ""
	@echo "Requirements:"
	@echo "  - macOS 15+ (Sequoia)"
	@echo "  - Swift 6+"
	@echo "  - Xcode 16+"
