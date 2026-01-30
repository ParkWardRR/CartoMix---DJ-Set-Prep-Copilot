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
[![Swift 6](https://img.shields.io/badge/Swift_6-F05138?style=for-the-badge&logo=swift&logoColor=white)](#architecture)
[![v0.3.2](https://img.shields.io/badge/v0.3.2--alpha-0A84FF?style=for-the-badge)](#changelog)

<br/>

[**Download**](#install) · [**Features**](#features) · [**Screenshots**](#screenshots) · [**How It Works**](#how-it-works) · [**Documentation**](#documentation)

<br/>

---

</div>

<br/>

## Why CartoMix?

<table>
<tr>
<td width="25%" align="center">
<h3>Native</h3>
<code>&lt;1s</code> startup<br/>
<code>~150MB</code> RAM<br/>
Zero Electron
</td>
<td width="25%" align="center">
<h3>Smart</h3>
OpenL3 embeddings<br/>
Section similarity<br/>
Neural Engine
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

### Waveform Label Painting

<img src="docs/assets/screens/waveform-painting.webp" alt="Waveform Painting" width="90%">

**Paint section labels directly on the waveform.** Drag to mark intros, drops, breakdowns, and outros. Your labels train the AI for better auto-detection.

</div>

<br/>

<table>
<tr>
<td width="50%">
<img src="docs/assets/screens/transition-detection.webp" alt="Transition Detection" width="100%">
<h4 align="center">Transition Detection</h4>
<p align="center">AI finds optimal mix-in/out points with phrase boundary awareness and energy-based scoring.</p>
</td>
<td width="50%">
<img src="docs/assets/screens/energy-matching.webp" alt="Energy Matching" width="100%">
<h4 align="center">Energy Curve Matching</h4>
<p align="center">Find tracks with compatible energy progressions: parallel, complementary, or continuation.</p>
</td>
</tr>
</table>

<br/>

<table>
<tr>
<td width="50%">
<img src="docs/assets/screens/audio-playback.webp" alt="Audio Playback" width="100%">
<h4 align="center">Real-Time Playback</h4>
<p align="center">Preview tracks with synchronized waveform. Jump to cues, scrub sections, keyboard shortcuts.</p>
</td>
<td width="50%">
<img src="docs/assets/screens/section-embeddings.webp" alt="Section Embeddings" width="100%">
<h4 align="center">Section-Level Embeddings</h4>
<p align="center">512-dim vectors for each section. Find tracks with similar intros, drops, or breakdowns.</p>
</td>
</tr>
</table>

<br/>

<table>
<tr>
<td width="50%">
<img src="docs/assets/screens/track-analysis.webp" alt="Track Analysis" width="100%">
<h4 align="center">Deep Track Analysis</h4>
<p align="center">BPM, key, energy, loudness (LUFS), cue points, sections—all computed locally on your Mac.</p>
</td>
<td width="50%">
<img src="docs/assets/screens/user-overrides.webp" alt="User Overrides" width="100%">
<h4 align="center">User Overrides</h4>
<p align="center">Edit BPM, key, cue points. Lock values to prevent re-analysis. Your edits are preserved.</p>
</td>
</tr>
</table>

<br/>

---

<br/>

## Screenshots

<div align="center">

| Library | Set Builder | Graph View |
|:---:|:---:|:---:|
| <img src="docs/assets/screens/library-view.webp" width="100%"> | <img src="docs/assets/screens/set-builder.webp" width="100%"> | <img src="docs/assets/screens/graph-view.webp" width="100%"> |
| Browse & search your collection | Build sets with drag & drop | Visualize track connections |

</div>

<br/>

---

<br/>

## Install

### Download Release

```bash
# Download from GitHub Releases
open https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot/releases/latest
```

### Build from Source

```bash
git clone https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot.git
cd CartoMix---DJ-Set-Prep-Copilot
make build-release
make run
```

**Requirements:** macOS 15+, Apple Silicon (M1+), Xcode 16+ (for building)

<br/>

---

<br/>

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CartoMix.app (SwiftUI)                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Library View  │  Set Builder  │  Graph View  │  Training     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  DardaniaCore: GRDB/SQLite • Similarity • Export • Planning   │  │
│  └───────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┼──────────────────────────────────────┘
                               │ XPC
┌──────────────────────────────▼──────────────────────────────────────┐
│                    AnalyzerXPC.xpc (Isolated Process)               │
│  Audio Decode → Beatgrid → Key → Energy → Sections → OpenL3 → Cues │
└─────────────────────────────────────────────────────────────────────┘
```

### 1. Import Your Library
Add music folders. CartoMix remembers access with security-scoped bookmarks.

### 2. Analyze Tracks
The XPC service runs isolated—a crash never freezes the UI. Analysis uses:
- **Neural Engine** for OpenL3 embeddings (512-dim vibe vectors)
- **Accelerate/vDSP** for beat detection and key analysis
- **Core ML** for section classification

### 3. Find Similar Tracks

```
Score = 0.50 × Vibe (OpenL3)
      + 0.20 × Tempo (BPM)
      + 0.20 × Key (Harmonic)
      + 0.10 × Energy
```

Every match includes an explanation:
> *"similar vibe (82%); Δ+2 BPM; key: 8A→9A (compatible); energy +1"*

### 4. Build Your Set
Drag tracks, reorder, visualize in Graph View.

### 5. Export
One click to Rekordbox, Serato, or Traktor—cue points, tempo, key intact.

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

<br/>

---

<br/>

## Documentation

- [Demo Procedures](docs/demo/DEMO_PROCEDURES.md) — Recording guidelines
- [Test Suite](docs/demo/TEST_SUITE.md) — Reproducible test procedures

### Development

```bash
make build          # Debug build
make build-release  # Release build
make test           # Run all tests
make screenshots    # Generate documentation screenshots
make help           # Show all targets
```

<br/>

---

<br/>

## Roadmap

**v0.3.x (Current)**
- [x] SwiftUI-first UI with XPC isolation
- [x] OpenL3 similarity + section embeddings
- [x] Waveform painting & real-time playback
- [x] Transition detection & energy matching
- [x] User override layer
- [x] Rekordbox/Serato/Traktor export

**v0.4.0 (Next)**
- [ ] Beatgrid editing
- [ ] Loop region markers
- [ ] Harmonic mixing wheel
- [ ] Set flow visualization

**v1.0.0 (Stable)**
- [ ] Sparkle auto-updates
- [ ] Homebrew distribution

<br/>

---

<br/>

## Contributing

```bash
git clone https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot.git
cd CartoMix---DJ-Set-Prep-Copilot
make build && make test
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

*Powered by SwiftUI, Core ML, Neural Engine, and Apple Silicon.*

<br/>

[![GitHub stars](https://img.shields.io/github/stars/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot?style=social)](https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot)
[![GitHub forks](https://img.shields.io/github/forks/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot?style=social)](https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot/fork)

<br/>

*Codename: Dardania*

</div>
