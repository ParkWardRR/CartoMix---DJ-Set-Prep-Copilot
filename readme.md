<div align="center">

<!-- HERO ANIMATION -->
<img src="docs/assets/video/cartomix-hero.webp" alt="CartoMix - AI-Powered DJ Set Prep" width="100%" style="border-radius: 12px; margin-bottom: 20px;">

<br/>

# CartoMix

### The AI-Powered DJ Set Prep Copilot

**Neural Engine-accelerated track analysis. Section-level vibe matching. One-click export to your DJ software.**

<br/>

[![macOS 15+](https://img.shields.io/badge/macOS_15+-000000?style=for-the-badge&logo=apple&logoColor=white)](#requirements)
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-000000?style=for-the-badge&logo=apple&logoColor=white)](#performance)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](#architecture)
[![Swift 6](https://img.shields.io/badge/Swift_6-F05138?style=for-the-badge&logo=swift&logoColor=white)](#architecture)
[![v0.4.0](https://img.shields.io/badge/v0.4.0--alpha-0A84FF?style=for-the-badge)](#changelog)

<br/>

[**Download**](#install) · [**Features**](#features) · [**Screenshots**](#screenshots) · [**How It Works**](#how-it-works) · [**Documentation**](#documentation)

<br/>

---

</div>

<br/>

## What's New in v0.4.0

**Hybrid Flutter + Native Swift Architecture**

- **Flutter UI** — Beautiful, responsive interface inspired by the web version
- **Native Swift Backend** — All audio analysis stays on Apple Silicon with Neural Engine acceleration
- **Platform Channels** — Seamless communication between Flutter and native code
- **Zero Performance Compromise** — Flutter for UI, Swift for computation

<br/>

---

<br/>

## Why CartoMix?

<table>
<tr>
<td width="25%" align="center">
<h3>Native</h3>
<code>&lt;1s</code> startup<br/>
<code>~150MB</code> RAM<br/>
Neural Engine
</td>
<td width="25%" align="center">
<h3>Smart</h3>
OpenL3 embeddings<br/>
Section similarity<br/>
Energy matching
</td>
<td width="25%" align="center">
<h3>Private</h3>
100% offline<br/>
No cloud ever<br/>
No telemetry
</td>
<td width="25%" align="center">
<h3>Pro</h3>
Rekordbox export<br/>
Serato export<br/>
Traktor export
</td>
</tr>
</table>

<br/>

---

<br/>

## Features

<div align="center">

### Modern Dark UI

**Professional dark theme matching industry-standard DJ software.** Clean waveforms, color-coded energy levels, smooth animations.

</div>

<br/>

<table>
<tr>
<td width="50%">
<h4 align="center">Library View</h4>
<p align="center">Browse & search your collection with list/grid view toggle. Filter by analyzed status, energy level, BPM range.</p>
</td>
<td width="50%">
<h4 align="center">Waveform View</h4>
<p align="center">Full waveform display with section overlays, cue markers, beat grid, and playhead with glow effect.</p>
</td>
</tr>
</table>

<br/>

<table>
<tr>
<td width="50%">
<h4 align="center">Set Builder</h4>
<p align="center">Build sets with drag & drop. Energy arc visualization shows your set's energy journey.</p>
</td>
<td width="50%">
<h4 align="center">Graph View</h4>
<p align="center">Visualize track connections. See BPM/key compatibility at a glance.</p>
</td>
</tr>
</table>

<br/>

### Color-Coded Energy System

| Energy | Color | Description |
|:------:|:-----:|-------------|
| 1-3 | 🟢 Green | Low energy / Warm-up |
| 4-5 | 🔵 Blue | Medium energy / Building |
| 6-7 | 🟡 Yellow | High energy / Peak time |
| 8-10 | 🔴 Red | Peak energy / Main room |

<br/>

### Section Detection

| Section | Color | Typical Use |
|---------|-------|-------------|
| Intro | Green | Mix-in point |
| Build | Yellow | Energy increase |
| Drop | Red | Peak moment |
| Breakdown | Purple | Mix-out opportunity |
| Outro | Blue | Transition zone |

<br/>

---

<br/>

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                       CartoMix (Flutter UI)                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Library View  │  Set Builder  │  Graph View  │  Settings     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │              Platform Channels (Method + Event)                │  │
│  │  database • analyzer • player • similarity • planner • exporter│  │
│  └───────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┼──────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────────┐
│                     Native Swift Backend                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  DardaniaCore: GRDB/SQLite • Similarity • Export • Planning   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │ XPC                                   │
│  ┌───────────────────────────▼───────────────────────────────────┐  │
│  │              AnalyzerXPC (Isolated Process)                    │  │
│  │  Audio Decode → Beatgrid → Key → Energy → Sections → OpenL3   │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Platform Channels

| Channel | Type | Purpose |
|---------|------|---------|
| `cartomix/database` | Method | Track CRUD, search, filtering |
| `cartomix/analyzer` | Method | Trigger analysis, get status |
| `cartomix/analyzer.progress` | Event | Live progress updates |
| `cartomix/player` | Method | Play, pause, seek, scrub |
| `cartomix/player.state` | Event | Playback state changes |
| `cartomix/similarity` | Method | Find similar tracks |
| `cartomix/planner` | Method | Set optimization |
| `cartomix/exporter` | Method | Export to DJ software |

<br/>

---

<br/>

## Install

### Download Release

```bash
# Download from GitHub Releases
open https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot/releases/latest
```

### Build from Source (Flutter)

```bash
# Clone repository
git clone https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot.git
cd CartoMix---DJ-Set-Prep-Copilot/cartomix_flutter

# Install dependencies
flutter pub get

# Build for macOS
flutter build macos

# Run
open build/macos/Build/Products/Release/cartomix_flutter.app
```

### Build from Source (Native Swift)

```bash
cd CartoMix---DJ-Set-Prep-Copilot
make build-release
make run
```

**Requirements:**
- macOS 15+ (Sequoia)
- Apple Silicon (M1+)
- Flutter 3.6+ (for Flutter build)
- Xcode 16+ (for native build)

<br/>

---

<br/>

## Performance

| Engine | Framework | Task | Speedup |
|--------|-----------|------|---------|
| Neural Engine | Core ML | OpenL3 embeddings | **15x** vs CPU |
| GPU | Metal | Spectrogram, onset | **10x** vs CPU |
| CPU | Accelerate | FFT, beatgrid, key | **4x** vs naive |
| Media Engine | AVFoundation | Decode FLAC/AAC/MP3 | Hardware |

**Zero-copy unified memory** — no data moves between CPU, GPU, and Neural Engine.

<br/>

---

<br/>

## Export Formats

| Format | File | What's Included |
|--------|------|-----------------|
| **Rekordbox** | XML | Cues, tempo, key, metadata, hot cues |
| **Serato** | .crate | Path refs, cue markers, BPM/key |
| **Traktor** | NML | CUE_V2, key mapping (0-23), metadata |
| **JSON** | .json | Full analysis + embeddings |
| **M3U8** | Playlist | Duration, artist, title |
| **CSV** | Spreadsheet | All metadata columns |

All exports include **SHA-256 checksums** for verification.

<br/>

---

<br/>

## Privacy

| | |
|---|---|
| Cloud upload | **Never** |
| Telemetry | **None** |
| Account required | **No** |
| Works offline | **100%** |
| App Sandbox | **Enabled** |
| Notarized | **Yes** |
| Hardened Runtime | **Yes** |

**Your music. Your data. Your Mac. Nothing leaves.**

<br/>

---

<br/>

## Requirements

| | Minimum | Recommended |
|---|---------|-------------|
| macOS | 15 (Sequoia) | 15+ |
| Chip | Apple Silicon (M1) | M2+ |
| RAM | 8 GB | 16 GB |
| Storage | 500 MB | 1 GB+ |
| Flutter | 3.6+ | Latest stable |

<br/>

---

<br/>

## Project Structure

```
cartomix/
├── Sources/
│   ├── DardaniaCore/       # Native Swift business logic
│   │   ├── Models.swift    # Core data models
│   │   ├── Database.swift  # GRDB/SQLite
│   │   ├── Similarity.swift
│   │   └── Export.swift
│   ├── Dardania/           # SwiftUI app (legacy)
│   └── AnalyzerXPC/        # Audio analysis service
│
├── cartomix_flutter/       # Flutter UI
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/      # Colors, typography, spacing
│   │   │   └── platform/   # Native bridge
│   │   ├── models/         # Dart data models
│   │   └── ui/
│   │       ├── screens/    # Main screens
│   │       └── widgets/    # Reusable components
│   ├── macos/              # macOS platform code
│   └── assets/             # Icons, fonts
│
└── docs/                   # Documentation
```

<br/>

---

<br/>

## Development

### Flutter Commands

```bash
cd cartomix_flutter

# Run in debug mode
flutter run -d macos

# Build release
flutter build macos

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Native Swift Commands

```bash
make build          # Debug build
make build-release  # Release build
make test           # Run all tests
make help           # Show all targets
```

<br/>

---

<br/>

## Roadmap

**v0.4.x (Current)**
- [x] Flutter UI with native Swift backend
- [x] Hybrid architecture via Platform Channels
- [x] Dark theme matching web UI
- [x] Waveform with sections, cues, beat grid
- [x] Energy arc visualization
- [x] List/grid view toggle
- [ ] Full Platform Channel integration

**v0.5.0 (Next)**
- [ ] Real-time audio playback
- [ ] Drag-and-drop set building
- [ ] Beatgrid editing
- [ ] Loop region markers

**v1.0.0 (Stable)**
- [ ] Sparkle auto-updates
- [ ] Homebrew distribution
- [ ] Full feature parity

<br/>

---

<br/>

## Contributing

```bash
git clone https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot.git
cd CartoMix---DJ-Set-Prep-Copilot/cartomix_flutter
flutter pub get
flutter run -d macos
```

<br/>

---

<br/>

## License

[Blue Oak Model License 1.0.0](LICENSE)

<br/>

---

<div align="center">

<br/>

**Built for DJs who want native performance and total privacy.**

*Powered by Flutter, Swift, Core ML, Neural Engine, and Apple Silicon.*

<br/>

[![GitHub stars](https://img.shields.io/github/stars/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot?style=social)](https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot)
[![GitHub forks](https://img.shields.io/github/forks/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot?style=social)](https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot/fork)

<br/>

*Codename: Shanghai*

</div>
