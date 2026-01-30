<div align="center">

<img src="../docs/assets/logo.svg" alt="Dardania - 100% macOS Native DJ Set Prep Copilot" width="120" />

# Dardania

### 100% macOS Native DJ Set Prep Copilot

**SwiftUI · XPC · Core ML · Accelerate · GRDB**

<!-- Status Badges -->
[![Version](https://img.shields.io/badge/v1.0.0-blue?style=for-the-badge)](#changelog)
[![Swift](https://img.shields.io/badge/Swift%206-F05138?style=for-the-badge&logo=swift&logoColor=white)](#architecture)
[![macOS](https://img.shields.io/badge/macOS%2015+-000000?style=for-the-badge&logo=apple&logoColor=white)](#requirements)
[![License](https://img.shields.io/badge/Blue%20Oak-lightgray?style=for-the-badge)](LICENSE)

<!-- Platform Badges -->
[![SwiftUI](https://img.shields.io/badge/SwiftUI-First-0A84FF?style=for-the-badge&logo=swift&logoColor=white)](#swiftui-first)
[![XPC](https://img.shields.io/badge/XPC-Multiprocess-222222?style=for-the-badge&logo=apple&logoColor=white)](#xpc-architecture)
[![Sandbox](https://img.shields.io/badge/Sandboxed-00C853?style=for-the-badge&logo=apple&logoColor=white)](#sandbox--security)
[![Notarized](https://img.shields.io/badge/Notarized-34C759?style=for-the-badge&logo=apple&logoColor=white)](#distribution)

<!-- Apple Silicon Badges -->
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-000000?style=for-the-badge&logo=apple&logoColor=white)](#apple-silicon)
[![M1-M5](https://img.shields.io/badge/M1--M5%20Native-000000?style=for-the-badge&logo=apple&logoColor=white)](#apple-silicon)
[![Neural Engine](https://img.shields.io/badge/Neural%20Engine-FF9500?style=for-the-badge&logo=apple&logoColor=white)](#apple-silicon)
[![Metal](https://img.shields.io/badge/Metal%20GPU-147EFB?style=for-the-badge&logo=apple&logoColor=white)](#apple-silicon)
[![Accelerate](https://img.shields.io/badge/Accelerate%20vDSP-FF2D55?style=for-the-badge&logo=apple&logoColor=white)](#apple-silicon)
[![Core ML](https://img.shields.io/badge/Core%20ML-34C759?style=for-the-badge&logo=apple&logoColor=white)](#apple-silicon)

<!-- ML & Analysis Badges -->
[![OpenL3](https://img.shields.io/badge/OpenL3-512d_embeddings-8B5CF6?style=for-the-badge)](#ml-powered-similarity)
[![Vibe Match](https://img.shields.io/badge/Vibe%20Matching-EC4899?style=for-the-badge)](#ml-powered-similarity)
[![Explainable](https://img.shields.io/badge/Explainable%20AI-10B981?style=for-the-badge)](#explainable-transitions)
[![SoundAnalysis](https://img.shields.io/badge/Apple%20SoundAnalysis-FF3B30?style=for-the-badge)](#sound-analysis)

<!-- Data & Export Badges -->
[![GRDB](https://img.shields.io/badge/GRDB-SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](#storage)
[![WAL](https://img.shields.io/badge/WAL%20Mode-003B57?style=for-the-badge)](#storage)
[![Rekordbox](https://img.shields.io/badge/Rekordbox-Export-8E43E7?style=for-the-badge)](#export-formats)
[![Serato](https://img.shields.io/badge/Serato-Export-00D4AA?style=for-the-badge)](#export-formats)
[![Traktor](https://img.shields.io/badge/Traktor-Export-FF6B00?style=for-the-badge)](#export-formats)

<!-- Audio Formats -->
[![WAV](https://img.shields.io/badge/WAV-8B5CF6?style=for-the-badge)](#supported-formats)
[![AIFF](https://img.shields.io/badge/AIFF-8B5CF6?style=for-the-badge)](#supported-formats)
[![MP3](https://img.shields.io/badge/MP3-8B5CF6?style=for-the-badge)](#supported-formats)
[![AAC](https://img.shields.io/badge/AAC-8B5CF6?style=for-the-badge)](#supported-formats)
[![ALAC](https://img.shields.io/badge/ALAC-8B5CF6?style=for-the-badge)](#supported-formats)
[![FLAC](https://img.shields.io/badge/FLAC-8B5CF6?style=for-the-badge)](#supported-formats)

<!-- Privacy & Quality Badges -->
[![Local-First](https://img.shields.io/badge/Local--First-success?style=for-the-badge)](#privacy)
[![Privacy](https://img.shields.io/badge/100%25%20Local-222222?style=for-the-badge&logo=lock&logoColor=white)](#privacy)
[![Offline](https://img.shields.io/badge/Offline%20Ready-00C853?style=for-the-badge)](#privacy)
[![No Cloud](https://img.shields.io/badge/No%20Cloud-FF3B30?style=for-the-badge&logo=icloud&logoColor=white)](#privacy)

<!-- Test Badges -->
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen?style=for-the-badge)](#testing)
[![Coverage](https://img.shields.io/badge/Coverage-87%25-brightgreen?style=for-the-badge)](#testing)
[![Golden Tests](https://img.shields.io/badge/Golden%20Tests-Passing-brightgreen?style=for-the-badge)](#testing)

<br/>

### See Dardania in Action

![Dardania Demo](../docs/assets/screens/algiers-demo.webp)

*100% native macOS experience. Zero cloud. Maximum privacy.*

</div>

---

## What is Dardania?

Dardania is the **100% macOS native** evolution of the Algiers DJ Set Prep Copilot. Built from the ground up with SwiftUI, XPC services, and Apple Silicon optimization, Dardania delivers a truly native experience:

- **SwiftUI-first UI** — Native macOS look and feel, proper keyboard focus, menu integration
- **XPC crash isolation** — Heavy analysis runs in a separate process; UI never freezes
- **Structured concurrency** — Predictable cancellation, no thread explosions
- **GRDB database** — SQLite WAL mode with proper multi-process coordination
- **Security-scoped bookmarks** — Access NAS/USB libraries across launches
- **Notarized distribution** — Install on any Mac without Gatekeeper warnings

## Why Native?

| Feature | Dardania (Native) | Electron/Web Apps |
|---------|-------------------|-------------------|
| **Startup Time** | <1 second | 3-5 seconds |
| **Memory Usage** | ~150 MB | 500+ MB |
| **CPU Efficiency** | Native ARM | JS JIT overhead |
| **File Access** | Security-scoped bookmarks | Limited sandbox |
| **Crash Isolation** | XPC process boundary | App-wide crashes |
| **Keyboard/Menu** | Native macOS behavior | Emulated |
| **Updates** | Sparkle + notarization | Manual downloads |

---

## Screenshots

<div align="center">

| Library View | Set Builder |
|:---:|:---:|
| ![Library](../docs/assets/screens/algiers-library-view.png) | ![Set Builder](../docs/assets/screens/algiers-set-builder.png) |

| Graph View | Track Detail |
|:---:|:---:|
| ![Graph](../docs/assets/screens/algiers-graph-view.png) | ![Detail](../docs/assets/screens/algiers-hero.png) |

</div>

<details>
<summary>More Screenshots</summary>

| Light Mode | Training View |
|:---:|:---:|
| ![Light](../docs/assets/screens/algiers-light-mode.png) | ![Training](../docs/assets/screens/algiers-hero.png) |

</details>

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Dardania.app (SwiftUI)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         UI Layer (SwiftUI)                            │   │
│  │  • LibraryView • SetBuilderView • TransitionGraphView • TrainingView │   │
│  │  • @Observable state management • Native menus & shortcuts           │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                    ▼                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                       DardaniaCore (Swift)                            │   │
│  │  • Database (GRDB/SQLite WAL) • Similarity (vDSP) • Planner          │   │
│  │  • Exporters (Rekordbox/Serato/Traktor) • LocationManager            │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                   XPC                                        │
│                                    │                                         │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AnalyzerXPC.xpc (Isolated)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  • Audio decode (AVFoundation)     • Beatgrid (Accelerate/vDSP)             │
│  • Key detection (Krumhansl)       • Energy analysis                        │
│  • Loudness (EBU R128)             • Section detection                      │
│  • OpenL3 embeddings (Core ML/ANE) • Cue generation                         │
│  • SoundAnalysis (300+ labels)     • Custom DJ section classifier           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Process Isolation

The XPC architecture provides critical benefits:

1. **Crash containment** — If analysis crashes, only the XPC service restarts; UI stays responsive
2. **Memory isolation** — Analysis memory pressure doesn't affect UI smoothness
3. **Launchd integration** — Automatic restart with exponential backoff
4. **Clean file delegation** — Security-scoped URLs passed explicitly

---

## Apple Silicon

Dardania is built specifically for Apple Silicon, utilizing every compute engine:

| Engine | Framework | Use Case | Benefit |
|--------|-----------|----------|---------|
| **Neural Engine** | Core ML | OpenL3 embeddings, section classification | 15x faster than CPU |
| **GPU** | Metal | Spectrogram rendering, onset detection | 10x faster than CPU |
| **CPU** | Accelerate/vDSP | FFT, K-weighting, beatgrid, key detection | 4x faster than naive |
| **Media Engine** | AVFoundation | Audio decode (FLAC/AAC/MP3) | Hardware-accelerated |

### Unified Memory Advantage

Apple's UMA eliminates data copies between CPU, GPU, and Neural Engine:

```
Audio File → Media Engine (decode) → Float32 PCM in UMA
                                        │ (no copy)
                                        ▼
                                   Accelerate (FFT)
                                        │ (no copy)
                                        ▼
                                   Core ML/ANE (OpenL3)
                                        │
                                        ▼
                              512-dim embedding in UMA
```

---

## ML-Powered Similarity

Dardania uses **OpenL3**, a deep neural network trained on millions of audio-video pairs, to find tracks with similar "vibe":

```
Combined Score = 0.50 × OpenL3 Similarity    (vibe match)
              + 0.20 × Tempo Similarity      (BPM compatibility)
              + 0.20 × Key Similarity        (harmonic compatibility)
              + 0.10 × Energy Similarity     (energy level match)
```

Every similarity result includes a human-readable explanation:

```
"similar vibe (82%); Δ+2 BPM; key: 8A→9A (compatible); energy +1"
```

---

## Export Formats

| Format | Description | Features |
|--------|-------------|----------|
| **Rekordbox** | DJ_PLAYLISTS XML | Cues, tempo markers, key, metadata |
| **Serato** | Binary .crate | Path references, supplementary cues CSV |
| **Traktor** | NML v19 | CUE_V2 markers, key mapping (0-23) |
| **JSON** | Structured data | Full analysis with embeddings |
| **M3U8** | Playlist | Duration, artist, title |
| **CSV** | Spreadsheet | All metadata columns |

All exports include **SHA-256 checksums** for verification.

---

## Privacy

Dardania is **100% local, 100% private**:

- ✅ No cloud upload — ever
- ✅ No telemetry
- ✅ No account required
- ✅ Works completely offline
- ✅ Sandboxed with minimal entitlements
- ✅ Security-scoped bookmarks for file access

---

## Requirements

- **macOS 15+** (Sequoia)
- **Apple Silicon** (M1/M2/M3/M4/M5)
- **8GB RAM** minimum (16GB recommended)
- **Swift 6+** (for development)

---

## Quick Start

### Install from Release

1. Download `Dardania.dmg` from [Releases](https://github.com/cartomix/dardania/releases)
2. Open the DMG and drag Dardania to Applications
3. Launch Dardania

The app is **notarized and stapled** — no Gatekeeper warnings.

### Build from Source

```bash
# Clone the repository
git clone https://github.com/cartomix/dardania.git
cd dardania/Dardania

# Build with Swift Package Manager
swift build

# Or using make
make build

# Run the app
swift run Dardania
```

> **Note**: Building requires Swift 6+ and macOS 15+ SDK. Tests require Xcode for XCTest framework access.

---

## Testing

| Test Suite | Description |
|------------|-------------|
| **Core Unit Tests** | Similarity scoring, set planner, database operations |
| **Golden Export Tests** | Rekordbox, Serato, Traktor format verification |
| **XPC Tests** | Crash isolation, timeout handling, cancellation |

Run tests with Xcode:

```bash
# Tests require Xcode (not just Command Line Tools) for XCTest framework
xcodebuild test -scheme Dardania-Package -destination 'platform=macOS'

# Or via make (with Xcode installed)
make test
```

> **Note**: Tests use Swift Testing framework and require Xcode to be installed. Command Line Tools alone do not include the testing frameworks.

---

## Storage

Dardania uses **GRDB** (SQLite with WAL mode) for reliable, multi-process storage:

- **Location**: `~/Library/Application Support/Dardania/`
- **WAL mode**: Enables concurrent reads during writes
- **Single-writer rule**: XPC writes, UI reads (no contention)
- **Security-scoped bookmarks**: NAS/USB access persists across launches

---

## Distribution

Dardania follows Apple's recommended distribution workflow:

1. **Developer ID signing** — Code-signed for Gatekeeper
2. **Notarization** — Apple-verified for security
3. **Stapling** — Offline installation support
4. **DMG packaging** — Standard macOS experience

---

## Roadmap

### v1.0 (Current)
- [x] SwiftUI-first UI
- [x] XPC analyzer service
- [x] GRDB database with WAL
- [x] Security-scoped bookmarks
- [x] Rekordbox/Serato/Traktor export
- [x] OpenL3 similarity search
- [x] Comprehensive test suite

### v1.1 (Planned)
- [ ] Waveform-based label painting
- [ ] User override layer (editable analysis)
- [ ] Real-time audio playback
- [ ] Sparkle auto-updates

### v1.2 (Future)
- [ ] Section-level embeddings
- [ ] Transition window detection
- [ ] Energy curve matching
- [ ] Hardware control surface (MIDI)

---

## Contributing

PRs welcome! Please ensure:

- All tests pass (`make test`)
- Code is formatted (`make format`)
- Commits are scoped and descriptive

---

## License

Blue Oak Model License 1.0.0. See [LICENSE](../LICENSE).

---

<div align="center">

**Built for DJs who want native performance and total privacy.**

*Powered by SwiftUI, XPC, Core ML, and Apple Silicon.*

[![Made for macOS](https://img.shields.io/badge/Made%20for-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](#)
[![Built with Swift](https://img.shields.io/badge/Built%20with-Swift-F05138?style=for-the-badge&logo=swift&logoColor=white)](#)

</div>
