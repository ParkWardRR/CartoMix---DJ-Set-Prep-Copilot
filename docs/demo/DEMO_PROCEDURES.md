# CartoMix Demo Procedures

*Codename: Dardania*

This document outlines reproducible demo procedures for testing and showcasing CartoMix.

> ⚠️ **Note:** CartoMix (native macOS) is a complete rewrite and is **NOT compatible** with the [web-based prototype](https://github.com/ParkWardRR/cartomix-Web-Based-DJ-Copilot). Data, libraries, and configurations cannot be migrated between versions.

## Prerequisites

- macOS 15+ (Sequoia)
- Apple Silicon Mac (M1/M2/M3/M4/M5)
- Test music library (see [Test Suite](#test-suite) below)
- Screen recording software (QuickTime or OBS)

## Test Suite

### Recommended Test Tracks

The following tracks from `/Volumes/navidrome-music/Staging` provide excellent variety for testing:

#### Electronic/Dance
| Artist | Album | Why It's Good for Testing |
|--------|-------|---------------------------|
| Daft Punk | Random Access Memories | Clear beat structure, varied sections, high production |
| ZHU | ERUM | Modern electronic, distinct drops and breakdowns |
| FKJ | Various | Live instrumentation with electronic elements |

#### Rock/Classic
| Artist | Album | Why It's Good for Testing |
|--------|-------|---------------------------|
| Led Zeppelin | Various | Dynamic range, tempo changes, complex structures |
| Bill Withers | Just As I Am | Clean recordings, clear vocal/instrumental separation |

#### Hip-Hop/R&B
| Artist | Album | Why It's Good for Testing |
|--------|-------|---------------------------|
| Kanye West | Various | Sampled beats, layered production |
| Frank Ocean | Various | Complex arrangements, mood transitions |
| Jay-Z | Various | Clear beat patterns, varied BPM |

#### Classical/Jazz
| Artist | Album | Why It's Good for Testing |
|--------|-------|---------------------------|
| Beethoven | Complete Symphonies | Tests classical detection, tempo variations |
| Frank Sinatra | Various | Big band, varied tempos |
| Julie London | Whatever Julie Wants | Clean vocals, jazz arrangements |

---

## Demo Scenarios

### Demo 1: First Launch & Library Import

**Duration:** 2-3 minutes

1. **Launch CartoMix** (fresh install, no existing data)
2. **Add Music Folder** (Cmd+O)
   - Navigate to `/Volumes/navidrome-music/Staging/Daft Punk`
   - Select "Random Access Memories" folder
3. **Watch scan progress** in bottom bar
4. **Show Library View** - tracks appear with metadata
5. **Highlight:** Fast import, native file picker, progress indicator

### Demo 2: Track Analysis

**Duration:** 3-4 minutes

1. **Select a track** from library (e.g., "Get Lucky")
2. **Right-click → Analyze Track**
3. **Show analysis progress** in detail panel
4. **Once complete, show:**
   - BPM detection (116 BPM)
   - Key detection (F# minor / 4A)
   - Energy level
   - Cue points (auto-generated)
   - Waveform preview
5. **Highlight:** Neural Engine acceleration, XPC isolation

### Demo 3: Similarity Search

**Duration:** 2-3 minutes

1. **Select an analyzed track**
2. **Click "Find Similar"** or use keyboard shortcut
3. **Show similarity results:**
   - Vibe match percentage
   - BPM compatibility
   - Key compatibility (Camelot wheel)
   - Energy match
4. **Show explanation text** for each match
5. **Highlight:** OpenL3 embeddings, explainable AI

### Demo 4: Set Building

**Duration:** 3-4 minutes

1. **Switch to Set Builder** (Cmd+2)
2. **Drag tracks from library** to build a set
3. **Reorder tracks** with drag-and-drop
4. **Show transition suggestions** between adjacent tracks
5. **Show Graph View** (Cmd+3) - visualize track relationships
6. **Highlight:** Native drag-and-drop, smooth animations

### Demo 5: Export

**Duration:** 2-3 minutes

1. **With set built, go to File → Export**
2. **Choose Rekordbox format**
3. **Show export options:**
   - Include cue points
   - Include waveforms
4. **Export to Desktop**
5. **Open exported XML** in text editor to show structure
6. **Highlight:** Native file dialogs, format flexibility

---

## v0.3 Feature Demos

### Demo 6: Waveform Label Painting

**Duration:** 3-4 minutes

1. **Select an analyzed track** with clear sections
2. **Open Track Detail View** - waveform appears
3. **Enable Paint Mode** - click paint brush icon
4. **Select section type** from dropdown (Intro, Verse, Drop, etc.)
5. **Click and drag on waveform** to paint section
6. **Show section colors** appearing on waveform
7. **Paint multiple sections:** Intro → Verse → Build → Drop → Outro
8. **Highlight:** Interactive painting, color-coded sections, zoom controls

### Demo 7: Real-Time Audio Playback

**Duration:** 2-3 minutes

1. **With waveform visible**, click play button
2. **Show playhead moving** in sync with audio
3. **Click on waveform** to seek to position
4. **Click on a cue point** - audio jumps to cue
5. **Use keyboard shortcuts:**
   - Space = play/pause
   - Left/Right = skip 5 seconds
6. **Highlight:** Low-latency playback, waveform sync, keyboard control

### Demo 8: User Override Layer

**Duration:** 2-3 minutes

1. **Select a track** with analysis
2. **Click "Edit Analysis"** button
3. **Override BPM:**
   - Click BPM field
   - Enter correct value
   - Toggle "Lock" to prevent re-analysis
4. **Override Key:**
   - Select from key picker
   - Show Camelot wheel updates
5. **Add custom cue point:**
   - Right-click on waveform
   - Select cue type and color
   - Enter label
6. **Highlight:** User edits persist, locked values, custom cues

### Demo 9: Transition Window Detection

**Duration:** 3-4 minutes

1. **Open two analyzed tracks** side by side
2. **Click "Find Transition Points"** button
3. **Show detected mix-in points** (green markers)
4. **Show detected mix-out points** (red markers)
5. **Hover over a point** - show recommendation tooltip:
   - "Phrase boundary before drop"
   - "Breakdown section - good for long blend"
6. **Show optimal transition suggestion** between two tracks
7. **Highlight:** Phrase-aware, energy-based, explainable

### Demo 10: Energy Curve Matching

**Duration:** 3-4 minutes

1. **Select a track** with varied energy
2. **Click "Match Energy Curves"**
3. **Show energy curve visualization** (line graph)
4. **Show match results:**
   - Parallel matches (similar curve)
   - Complementary matches (opposite curve)
   - Continuation matches (seamless flow)
5. **Click a match** to see overlay comparison
6. **Show "Best Transition Point"** indicator
7. **Highlight:** Visual curve comparison, match types, transition points

### Demo 11: Section-Level Embeddings

**Duration:** 2-3 minutes

1. **Select a track** with multiple sections
2. **Expand "Section Analysis"** panel
3. **Show embedding for each section:**
   - Intro embedding
   - Drop embedding
   - Breakdown embedding
4. **Click "Find Similar Drops"** - searches for tracks with similar drop sections
5. **Show results** with section-specific matches
6. **Highlight:** Granular matching, section-aware similarity

---

## Video Recording Guidelines

### Setup
1. **Resolution:** 2560x1440 or 1920x1080
2. **Frame rate:** 60fps (smooth scrolling)
3. **Audio:** System audio + optional narration
4. **Window size:** Maximize or 1600x1000

### Recording Tips
- Use **dark mode** (default) for visual impact
- **Close other apps** for clean dock
- **Hide desktop icons** if visible
- **Use keyboard shortcuts** to show power-user features
- **Pause briefly** on key moments for viewer comprehension

### Post-Production
1. **Trim** dead time at start/end
2. **Speed up** repetitive operations (2x)
3. **Add captions** for key features
4. **Export as WebP** for web (see below)

---

## Converting Video to WebP

### Using FFmpeg (recommended)

```bash
# High quality, good size
ffmpeg -i demo.mov -vf "fps=30,scale=1280:-1" -loop 0 -quality 80 demo.webp

# Smaller file, lower quality
ffmpeg -i demo.mov -vf "fps=24,scale=960:-1" -loop 0 -quality 70 demo-small.webp

# Create animated preview (first 10 seconds)
ffmpeg -i demo.mov -t 10 -vf "fps=15,scale=800:-1" -loop 0 preview.webp
```

### File Size Targets
- **Hero video:** < 5MB (10-15 seconds)
- **Full demo:** < 20MB (1-2 minutes)
- **Preview loop:** < 2MB (5-10 seconds)

---

## Screenshot Guidelines

### Required Screenshots

**Core Views:**
1. **Library View** - Full window, populated with tracks
2. **Track Detail** - Analysis results, cue points visible
3. **Set Builder** - Set in progress with multiple tracks
4. **Graph View** - Node connections visible
5. **Similarity Results** - Search results with explanations
6. **Export Dialog** - Format options visible
7. **Settings** - ML settings tab (shows Neural Engine)

**v0.3 Features (NEW):**
8. **Waveform Painting** - Active paint mode with colored sections
9. **Audio Playback** - Playhead visible, transport controls
10. **User Overrides** - Edit panel with locked BPM/key
11. **Transition Detection** - Mix-in/out points on waveform
12. **Energy Matching** - Energy curve comparison overlay
13. **Section Embeddings** - Section list with similarity scores

### Capture Settings
- **Format:** PNG (lossless) → convert to WebP for web
- **Retina:** Capture at 2x, scale down for web
- **Window shadow:** Include for polished look

### Converting to WebP

```bash
# Single file
cwebp -q 90 screenshot.png -o screenshot.webp

# Batch convert
for f in *.png; do cwebp -q 90 "$f" -o "${f%.png}.webp"; done
```

---

## Reproducing This Demo

To recreate this demo from scratch:

```bash
# 1. Clone and build
git clone https://github.com/cartomix/cartomix.git
cd cartomix
swift build -c release

# 2. Run the app
.build/release/Dardania

# 3. Add test music folder
# Use Cmd+O and navigate to test tracks

# 4. Follow demo scenarios above
```

---

## Troubleshooting

### App won't launch
- Check macOS version (15+ required)
- Verify Apple Silicon (not Intel)
- Check Console.app for crash logs

### Analysis slow
- Ensure Neural Engine is available
- Check Activity Monitor for XPC process
- Reduce concurrent analyses in Settings

### Export issues
- Verify file permissions
- Check export location is writable
- Try different format (JSON as fallback)

---

*Last updated: January 2025*
