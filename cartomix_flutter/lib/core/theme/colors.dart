import 'package:flutter/material.dart';

/// CartoMix color system - Pro-first dark mode design
/// Exact match to web CSS variables from index.css
class CartoMixColors {
  CartoMixColors._();

  // MARK: - Background Colors (Dark Mode)
  // Matches: --color-bg, --color-bg-secondary, --color-bg-tertiary, --color-bg-elevated, --color-bg-hover
  static const Color bgPrimary = Color(0xFF0A0A0A);
  static const Color bgSecondary = Color(0xFF111111);
  static const Color bgTertiary = Color(0xFF1A1A1A);
  static const Color bgElevated = Color(0xFF252525);
  static const Color bgHover = Color(0xFF2D2D2D);

  // MARK: - Border Colors
  // Matches: --color-border, --color-border-light
  static const Color border = Color(0xFF252525);
  static const Color borderLight = Color(0xFF333333);
  static const Color borderFocus = primary;

  // MARK: - Text Colors
  // Matches: --color-text, --color-text-secondary, --color-text-muted
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF666666);

  // MARK: - Primary/Accent Colors (CSS naming)
  // Matches: --color-primary, --color-accent
  static const Color primary = Color(0xFF3B82F6); // Blue
  static const Color accent = Color(0xFFA78BFA); // Purple

  // MARK: - Semantic Colors
  // Matches: --color-success, --color-warning, --color-error
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFF87171);

  // MARK: - Accent Color Aliases (for backwards compatibility)
  static const Color accentBlue = primary;
  static const Color accentPurple = accent;
  static const Color accentGreen = success;
  static const Color accentYellow = warning;
  static const Color accentOrange = Color(0xFFFF9F0A);
  static const Color accentRed = error;
  static const Color accentPink = Color(0xFFFF375F);
  static const Color accentCyan = Color(0xFF64D2FF);

  // MARK: - Energy Level Colors (1-10 scale)
  // Matches web logic: >=8 red, >=6 yellow, >=4 blue, else green
  static const Color energyLow = success; // 1-3
  static const Color energyMid = primary; // 4-5
  static const Color energyHigh = warning; // 6-7
  static const Color energyPeak = error; // 8-10

  /// Get color for energy level (1-10) - matches web CSS logic
  static Color colorForEnergy(int energy) {
    if (energy >= 8) return energyPeak;
    if (energy >= 6) return energyHigh;
    if (energy >= 4) return energyMid;
    return energyLow;
  }

  // MARK: - Section Colors (solid)
  // Matches web CSS section color variables
  static const Color sectionIntro = Color(0xFF22C55E); // Green
  static const Color sectionVerse = Color(0xFF8B5CF6); // Violet
  static const Color sectionBuild = Color(0xFFEAB308); // Yellow
  static const Color sectionDrop = Color(0xFFEF4444); // Red
  static const Color sectionBreakdown = Color(0xFFA78BFA); // Purple
  static const Color sectionChorus = Color(0xFFEC4899); // Pink
  static const Color sectionOutro = Color(0xFF3B82F6); // Blue

  // MARK: - Section Overlay Colors (with 25% alpha for waveform backgrounds)
  // Matches web CSS: rgba(color, 0.25)
  static const Color sectionIntroOverlay = Color(0x4022C55E); // 25% green
  static const Color sectionVerseOverlay = Color(0x408B5CF6); // 25% violet
  static const Color sectionBuildOverlay = Color(0x40EAB308); // 25% yellow
  static const Color sectionDropOverlay = Color(0x40EF4444); // 25% red
  static const Color sectionBreakdownOverlay = Color(0x40A78BFA); // 25% purple
  static const Color sectionChorusOverlay = Color(0x40EC4899); // 25% pink
  static const Color sectionOutroOverlay = Color(0x403B82F6); // 25% blue

  /// Get solid color for section type
  static Color colorForSection(String type) {
    switch (type.toLowerCase()) {
      case 'intro':
        return sectionIntro;
      case 'verse':
        return sectionVerse;
      case 'build':
      case 'buildup':
        return sectionBuild;
      case 'drop':
        return sectionDrop;
      case 'breakdown':
      case 'break':
        return sectionBreakdown;
      case 'chorus':
        return sectionChorus;
      case 'outro':
        return sectionOutro;
      default:
        return textSecondary;
    }
  }

  /// Get overlay color (25% alpha) for section type - used in waveform backgrounds
  static Color colorForSectionOverlay(String type) {
    switch (type.toLowerCase()) {
      case 'intro':
        return sectionIntroOverlay;
      case 'verse':
        return sectionVerseOverlay;
      case 'build':
      case 'buildup':
        return sectionBuildOverlay;
      case 'drop':
        return sectionDropOverlay;
      case 'breakdown':
      case 'break':
        return sectionBreakdownOverlay;
      case 'chorus':
        return sectionChorusOverlay;
      case 'outro':
        return sectionOutroOverlay;
      default:
        return textSecondary.withValues(alpha: 0.25);
    }
  }

  // MARK: - Cue Point Colors
  // Matches web CSS cue type colors
  static const Color cueLoad = Color(0xFF22C55E); // Green - load point
  static const Color cueDrop = Color(0xFFEF4444); // Red - drop
  static const Color cueBreakdown = Color(0xFFA78BFA); // Purple - breakdown
  static const Color cueBuild = Color(0xFFEAB308); // Yellow - build
  static const Color cueVocal = Color(0xFFEC4899); // Pink - vocal
  static const Color cueLoop = Color(0xFF3B82F6); // Blue - loop

  /// Get color for cue point type
  static Color colorForCue(String type) {
    switch (type.toLowerCase()) {
      case 'load':
        return cueLoad;
      case 'drop':
        return cueDrop;
      case 'breakdown':
      case 'break':
        return cueBreakdown;
      case 'build':
      case 'buildup':
        return cueBuild;
      case 'vocal':
        return cueVocal;
      case 'loop':
        return cueLoop;
      default:
        return primary;
    }
  }

  // MARK: - Camelot Key Colors (24 positions)
  static const Map<String, Color> camelotColors = {
    '1A': Color(0xFFFF6B6B),
    '1B': Color(0xFFFF8E6B),
    '2A': Color(0xFFFFB16B),
    '2B': Color(0xFFFFD46B),
    '3A': Color(0xFFF7FF6B),
    '3B': Color(0xFFD4FF6B),
    '4A': Color(0xFFB1FF6B),
    '4B': Color(0xFF6BFF6B),
    '5A': Color(0xFF6BFFB1),
    '5B': Color(0xFF6BFFD4),
    '6A': Color(0xFF6BFFF7),
    '6B': Color(0xFF6BD4FF),
    '7A': Color(0xFF6BB1FF),
    '7B': Color(0xFF6B8EFF),
    '8A': Color(0xFF6B6BFF),
    '8B': Color(0xFF8E6BFF),
    '9A': Color(0xFFB16BFF),
    '9B': Color(0xFFD46BFF),
    '10A': Color(0xFFF76BFF),
    '10B': Color(0xFFFF6BD4),
    '11A': Color(0xFFFF6BB1),
    '11B': Color(0xFFFF6B8E),
    '12A': Color(0xFFFF6B6B),
    '12B': Color(0xFFFF8E8E),
  };

  /// Get color for Camelot key
  static Color colorForKey(String key) {
    return camelotColors[key.toUpperCase()] ?? accentGreen;
  }

  // MARK: - Status Colors
  static const Color statusPending = textMuted;
  static const Color statusAnalyzed = success;
  static const Color statusFailed = error;
  static const Color statusAnalyzing = primary;

  // MARK: - Waveform Colors
  // Matches: --color-waveform (unplayed), --color-waveform-played
  static const Color waveformUnplayed = primary; // Blue
  static const Color waveformPlayed = accent; // Purple
  static const Color waveformPlayhead = accent; // Purple with glow
  static const Color waveformPlayheadGlow = Color(0x40A78BFA); // 25% purple glow

  // MARK: - Beat Grid Colors
  static const Color beatGridStrong = Color(0x33FFFFFF); // Every 4 beats (20% white)
  static const Color beatGridWeak = Color(0x1AFFFFFF); // Other beats (10% white)

  // MARK: - Transition Score Colors
  static Color colorForTransitionScore(double score) {
    if (score >= 8) return success;
    if (score >= 6) return primary;
    return textMuted;
  }

  // MARK: - Selection/Highlight Colors
  static const Color selection = Color(0x333B82F6); // 20% primary
  static const Color selectionBorder = primary;
  static const Color hoverHighlight = Color(0x1A3B82F6); // 10% primary
}
