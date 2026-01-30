# CartoMix Test Suite

*Codename: Dardania*

This document defines the standard test tracks and expected results for validating CartoMix functionality.

## Test Music Location

Primary test library: `/Volumes/navidrome-music/Staging`

## Core Test Tracks

### Track Set A: Electronic (BPM Detection)

| # | Artist | Track | Expected BPM | Expected Key | Notes |
|---|--------|-------|--------------|--------------|-------|
| A1 | Daft Punk | Get Lucky | 116 | F#m / 4A | Clear 4/4, consistent tempo |
| A2 | Daft Punk | Giorgio by Moroder | 78 | Gm / 6A | Tempo changes, spoken word |
| A3 | Daft Punk | Instant Crush | 106 | D / 10B | Syncopated rhythm |
| A4 | ZHU | Faded | 108 | F#m / 4A | Deep house, clear drops |

### Track Set B: Rock (Section Detection)

| # | Artist | Track | Expected Sections | Notes |
|---|--------|-------|-------------------|-------|
| B1 | Led Zeppelin | Stairway to Heaven | Intro, Verse, Build, Solo, Outro | Classic structure, tempo change |
| B2 | Led Zeppelin | Black Dog | Intro, Verse, Chorus, Bridge | Odd meter riff |
| B3 | Led Zeppelin | Kashmir | Intro, Main, Build, Peak | Sustained energy |

### Track Set C: Hip-Hop (Cue Point Detection)

| # | Artist | Track | Expected Cues | Notes |
|---|--------|-------|---------------|-------|
| C1 | Kanye West | Stronger | Drop, Build, Breakdown | Sample-based |
| C2 | Jay-Z | N****s in Paris | Drop, Build, Switch | Multiple sections |
| C3 | Frank Ocean | Nights | Transition point | Famous beat switch |

### Track Set D: Classical (Edge Cases)

| # | Artist | Track | Test Purpose |
|---|--------|-------|--------------|
| D1 | Beethoven | Symphony No. 5, Mvt 1 | Tempo variation, no clear "beat" |
| D2 | Beethoven | Moonlight Sonata | Slow tempo, piano solo |

### Track Set E: Jazz/Vocal (Energy Analysis)

| # | Artist | Track | Expected Energy | Notes |
|---|--------|-------|-----------------|-------|
| E1 | Bill Withers | Ain't No Sunshine | Low-Medium | Sparse arrangement |
| E2 | Bill Withers | Lovely Day | Medium-High | Upbeat, iconic vocal |
| E3 | Frank Sinatra | Fly Me to the Moon | Medium | Big band, swing |

---

## Test Scenarios

### Scenario 1: Basic Import

**Tracks:** A1, A2
**Steps:**
1. Import "Random Access Memories" folder
2. Verify metadata extraction (artist, title, album)
3. Verify file size and format detection
4. Verify no crashes on import

**Pass Criteria:**
- [ ] All tracks appear in library
- [ ] Metadata is correct
- [ ] No error messages
- [ ] Import completes < 5 seconds

### Scenario 2: BPM Accuracy

**Tracks:** A1, A2, A3, A4
**Steps:**
1. Analyze all tracks
2. Compare detected BPM to known values
3. Check BPM confidence scores

**Pass Criteria:**
- [ ] BPM within ±1 of expected
- [ ] Confidence > 0.85 for clear tracks
- [ ] A2 may have lower confidence (acceptable)

### Scenario 3: Key Detection

**Tracks:** A1, A4
**Steps:**
1. Analyze tracks
2. Compare detected key to known values
3. Verify Camelot wheel notation

**Pass Criteria:**
- [ ] Key matches or is relative major/minor
- [ ] Camelot notation is correct
- [ ] Confidence > 0.7

### Scenario 4: Section Detection

**Tracks:** B1, B2
**Steps:**
1. Analyze tracks
2. Review detected sections
3. Compare to known song structure

**Pass Criteria:**
- [ ] Major sections identified
- [ ] Intro/outro detected
- [ ] Drops/builds detected where applicable

### Scenario 5: Similarity Search

**Tracks:** A1, A2, A3, A4
**Steps:**
1. Analyze all tracks
2. Select A1, find similar
3. Verify ranking makes sense

**Pass Criteria:**
- [ ] A4 (Faded) ranks high (similar vibe)
- [ ] A3 (Instant Crush) ranks medium
- [ ] A2 (Giorgio) ranks lower (different vibe)
- [ ] Explanations are sensible

### Scenario 6: Export Validation

**Tracks:** A1, A2
**Steps:**
1. Build set with both tracks
2. Export as Rekordbox XML
3. Validate XML structure

**Pass Criteria:**
- [ ] XML is well-formed
- [ ] Cue points present
- [ ] Tempo markers present
- [ ] File paths are correct

### Scenario 7: Stress Test

**Tracks:** Full "Led Zeppelin" folder (50+ tracks)
**Steps:**
1. Import entire folder
2. Start batch analysis
3. Monitor memory usage
4. Verify XPC crash isolation

**Pass Criteria:**
- [ ] Import completes successfully
- [ ] Analysis doesn't freeze UI
- [ ] Memory stays < 1GB
- [ ] No app crashes

### Scenario 8: Edge Cases

**Tracks:** D1, D2
**Steps:**
1. Analyze classical tracks
2. Verify graceful handling

**Pass Criteria:**
- [ ] No crashes
- [ ] BPM shows "variable" or low confidence
- [ ] Key still detected
- [ ] No false cue points

---

## Expected Results Reference

### BPM Reference Table

| Track | Expected | Tolerance | Notes |
|-------|----------|-----------|-------|
| Get Lucky | 116 | ±0.5 | Very stable |
| Giorgio by Moroder | 78 | ±2 | Tempo shifts |
| Instant Crush | 106 | ±1 | Syncopated |
| Faded | 108 | ±0.5 | Very stable |

### Key Reference Table

| Track | Expected Key | Camelot | Notes |
|-------|--------------|---------|-------|
| Get Lucky | F# minor | 4A | Clear harmonic content |
| Faded | F# minor | 4A | Same key (good for mixing) |
| Instant Crush | D major | 10B | May detect as Bm (relative) |

---

## Automated Test Commands

```bash
# Run unit tests
make test-core

# Run golden export tests
make test-golden

# Run XPC tests
make test-xpc

# Run all tests
make test
```

---

## Reporting Issues

When a test fails, capture:

1. **Track info:** Artist, title, format, duration
2. **Expected result:** From table above
3. **Actual result:** What CartoMix detected
4. **Screenshot:** Of the analysis view
5. **Logs:** From Console.app (search "dardania")

File issues at: https://github.com/cartomix/cartomix/issues

---

*Last updated: January 2025*
