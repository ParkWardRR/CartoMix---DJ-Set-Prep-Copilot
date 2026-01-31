# CartoMix Roadmap

## Vision

CartoMix is the AI-powered DJ set preparation copilot — native, private, and professional. Our goal is to help DJs build better sets faster using Neural Engine-accelerated track analysis, intelligent section matching, and seamless export to industry-standard DJ software.

---

## Current Release

### v0.4.0-beta (January 2026) — First Public Beta

**Status:** Released

The first public beta establishes the hybrid Flutter + Swift architecture and delivers a polished, professional UI.

| Feature | Status |
|---------|--------|
| Hybrid Flutter UI + Native Swift Backend | ✅ Complete |
| First-launch onboarding wizard | ✅ Complete |
| Custom navigation with glow effects | ✅ Complete |
| Library screen with search & filtering | ✅ Complete |
| Set Builder screen with energy journey | ✅ Complete |
| Graph screen with similarity controls | ✅ Complete |
| Settings screen with all sections | ✅ Complete |
| 23 comprehensive widget tests | ✅ Complete |
| macOS code signing & notarization | ✅ Complete |
| Hardened runtime enabled | ✅ Complete |

---

## Upcoming Releases

### v0.5.0 — Native Integration (Q1 2026)

Connect the Flutter UI to the native Swift backend via Platform Channels.

| Feature | Status |
|---------|--------|
| Database channel integration | 🔄 In Progress |
| Track loading from GRDB/SQLite | ⏳ Planned |
| Music folder scanning | ⏳ Planned |
| Track metadata display | ⏳ Planned |
| Analyzer channel integration | ⏳ Planned |
| Analysis progress streaming | ⏳ Planned |
| Player channel integration | ⏳ Planned |
| Real-time waveform playhead | ⏳ Planned |

### v0.6.0 — Audio Playback (Q2 2026)

Full audio playback with waveform visualization and section markers.

| Feature | Status |
|---------|--------|
| Audio playback controls | ⏳ Planned |
| Gradient waveform painter | ⏳ Planned |
| Section overlay visualization | ⏳ Planned |
| Cue point markers | ⏳ Planned |
| Seek gesture handling | ⏳ Planned |
| Beat grid display | ⏳ Planned |
| Playhead with glow effect | ⏳ Planned |

### v0.7.0 — Set Building (Q2 2026)

Interactive set building with drag-and-drop and energy optimization.

| Feature | Status |
|---------|--------|
| Drag-and-drop track ordering | ⏳ Planned |
| Energy journey visualization | ⏳ Planned |
| Set optimization (warm-up/peak/open) | ⏳ Planned |
| BPM range validation | ⏳ Planned |
| Key compatibility warnings | ⏳ Planned |
| Transition suggestions | ⏳ Planned |

### v0.8.0 — Graph Visualization (Q3 2026)

Force-directed graph showing track relationships and similarity scores.

| Feature | Status |
|---------|--------|
| Force-directed graph layout | ⏳ Planned |
| Similarity edge rendering | ⏳ Planned |
| Node selection and details | ⏳ Planned |
| Zoom and pan controls | ⏳ Planned |
| Filter by similarity threshold | ⏳ Planned |
| Set-only view mode | ⏳ Planned |

### v0.9.0 — Export & Import (Q3 2026)

Full export support for all major DJ software platforms.

| Feature | Status |
|---------|--------|
| Rekordbox XML export | ⏳ Planned |
| Serato crate export | ⏳ Planned |
| Traktor NML export | ⏳ Planned |
| JSON export with embeddings | ⏳ Planned |
| M3U8 playlist export | ⏳ Planned |
| CSV metadata export | ⏳ Planned |
| SHA-256 checksum verification | ⏳ Planned |

---

## v1.0.0 — Stable Release (Q4 2026)

The first stable release with full feature parity and production polish.

| Feature | Status |
|---------|--------|
| All platform channels integrated | ⏳ Planned |
| Full audio analysis pipeline | ⏳ Planned |
| Complete export support | ⏳ Planned |
| Sparkle auto-updates | ⏳ Planned |
| Homebrew distribution | ⏳ Planned |
| Performance optimization | ⏳ Planned |
| Memory profiling & cleanup | ⏳ Planned |
| Comprehensive test coverage | ⏳ Planned |

---

## Future Considerations (Post-1.0)

These features are on our radar but not yet scheduled:

- **Beatgrid editing** — Manual beat alignment and adjustment
- **Loop region markers** — Define and save loop points
- **Hot cue management** — Create and organize hot cues
- **Playlist folders** — Organize tracks into hierarchical folders
- **Smart playlists** — Auto-updating playlists based on criteria
- **Batch analysis** — Analyze entire folders in background
- **Analysis presets** — Save and load analysis configurations
- **Keyboard shortcuts** — Power-user navigation and control
- **Touch Bar support** — macOS Touch Bar integration
- **iCloud sync** — Sync library across devices (optional)

---

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

---

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| App startup | < 1s | Cold start to usable UI |
| Memory usage | < 150 MB | Baseline with empty library |
| Track analysis | < 30s | Per track on M1 |
| Similarity query | < 100ms | Find similar tracks |
| Waveform render | 60 fps | Smooth scrolling |

---

## Contributing

We welcome contributions! See the main [README](readme.md) for development setup.

Priority areas for contribution:
- Widget tests for new screens
- Platform channel implementations
- Performance optimizations
- Documentation improvements

---

## Changelog

See [GitHub Releases](https://github.com/ParkWardRR/CartoMix---DJ-Set-Prep-Copilot/releases) for detailed release notes.

---

*Last updated: January 2026*
