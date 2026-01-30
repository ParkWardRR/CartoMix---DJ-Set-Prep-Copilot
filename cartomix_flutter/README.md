# CartoMix Flutter

The Flutter-based UI for CartoMix DJ Set Prep Copilot.

## Overview

This is the new Flutter frontend that provides a modern, responsive UI while leveraging the native Swift backend for audio analysis and Neural Engine acceleration.

## Features

- **Dark Pro Theme** - Matches industry-standard DJ software aesthetics
- **Waveform Visualization** - Section overlays, cue markers, beat grid, playhead with glow
- **Energy Arc** - SVG-style bezier curve showing set energy journey
- **List/Grid Views** - Toggle between compact list and visual grid layouts
- **Platform Channels** - Seamless communication with native Swift backend

## Getting Started

### Prerequisites

- macOS 15+ (Sequoia)
- Flutter 3.6+
- Xcode 16+ (for macOS builds)

### Installation

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run -d macos

# Build release
flutter build macos
```

### Running the App

```bash
# Debug mode with hot reload
flutter run -d macos

# Or open the built app
open build/macos/Build/Products/Release/cartomix_flutter.app
```

## Architecture

```
lib/
├── core/
│   ├── theme/           # Colors, typography, spacing, gradients
│   │   ├── colors.dart      # CSS-matched color system
│   │   ├── typography.dart  # Font styles
│   │   ├── spacing.dart     # Layout constants
│   │   ├── gradients.dart   # Waveform & UI gradients
│   │   └── theme.dart       # ThemeData configuration
│   └── platform/
│       └── native_bridge.dart  # Platform channel definitions
│
├── models/              # Data models (mirrors Swift models)
│   ├── track.dart
│   ├── track_analysis.dart
│   ├── track_section.dart
│   ├── cue_point.dart
│   └── enums.dart
│
└── ui/
    ├── screens/
    │   ├── main_screen.dart      # Navigation shell
    │   ├── library_screen.dart   # Track library
    │   ├── set_builder_screen.dart
    │   ├── graph_screen.dart
    │   └── settings_screen.dart
    └── widgets/
        ├── common/
        │   └── colored_badge.dart
        ├── library/
        │   ├── track_card.dart
        │   └── track_list_item.dart
        ├── waveform/
        │   └── waveform_view.dart
        └── set_builder/
            └── energy_arc.dart
```

## Theme System

### Colors

The color system matches the web UI CSS variables:

```dart
// Primary colors
CartoMixColors.primary     // #3B82F6 (blue)
CartoMixColors.accent      // #A78BFA (purple)
CartoMixColors.success     // #22C55E (green)
CartoMixColors.warning     // #EAB308 (yellow)
CartoMixColors.error       // #F87171 (red)

// Background colors
CartoMixColors.bgPrimary   // #0A0A0A
CartoMixColors.bgSecondary // #111111
CartoMixColors.bgTertiary  // #1A1A1A
```

### Energy Colors

```dart
// Energy level colors (1-10 scale)
CartoMixColors.colorForEnergy(energy)
// 1-3: Green (low)
// 4-5: Blue (medium)
// 6-7: Yellow (high)
// 8-10: Red (peak)
```

### Section Colors

```dart
// Section type colors
CartoMixColors.sectionIntro      // Green
CartoMixColors.sectionBuild      // Yellow
CartoMixColors.sectionDrop       // Red
CartoMixColors.sectionBreakdown  // Purple
CartoMixColors.sectionOutro      // Blue

// Section overlays (25% alpha)
CartoMixColors.colorForSectionOverlay(type)
```

## Platform Channels

The app communicates with the native Swift backend via platform channels:

| Channel | Type | Purpose |
|---------|------|---------|
| `cartomix/database` | Method | Track CRUD |
| `cartomix/analyzer` | Method | Analysis control |
| `cartomix/analyzer.progress` | Event | Progress updates |
| `cartomix/player` | Method | Playback control |
| `cartomix/player.state` | Event | State changes |
| `cartomix/similarity` | Method | Find similar |
| `cartomix/planner` | Method | Set optimization |
| `cartomix/exporter` | Method | Export to DJ software |

## Dependencies

- `flutter_riverpod` - State management
- `freezed_annotation` - Immutable models
- `window_manager` - macOS window control
- `intl` - Internationalization

## Development

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/

# Generate freezed models
flutter pub run build_runner build
```

## License

[Blue Oak Model License 1.0.0](../LICENSE)
