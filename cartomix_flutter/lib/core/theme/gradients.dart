import 'package:flutter/material.dart';
import 'colors.dart';

/// CartoMix gradient definitions for waveforms, energy curves, and UI elements
class CartoMixGradients {
  CartoMixGradients._();

  // MARK: - Waveform Gradients

  /// Waveform gradient colors (Cyan -> Blue -> Purple -> Pink)
  static const List<Color> waveformColors = [
    Color(0xFF64D2FF), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFFA78BFA), // Purple
    Color(0xFFFF375F), // Pink
  ];

  /// Horizontal waveform gradient
  static const LinearGradient waveform = LinearGradient(
    colors: waveformColors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Waveform gradient for played portion (more purple-shifted)
  static const LinearGradient waveformPlayed = LinearGradient(
    colors: [
      Color(0xFFA78BFA), // Purple
      Color(0xFF8B5CF6), // Darker purple
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // MARK: - Energy Gradients

  /// Energy curve colors (Orange -> Red -> Purple)
  static const List<Color> energyColors = [
    Color(0xFFFF9F0A), // Orange
    Color(0xFFF87171), // Red
    Color(0xFFA78BFA), // Purple
  ];

  /// Energy curve line gradient (horizontal)
  static const LinearGradient energyCurve = LinearGradient(
    colors: [
      Color(0xFF3B82F6), // Blue (low)
      Color(0xFFA78BFA), // Purple (mid)
      Color(0xFFF87171), // Red (high)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Energy arc fill gradient (bottom to top)
  static const LinearGradient energyFill = LinearGradient(
    colors: [
      Color(0x00000000), // Transparent
      Color(0x33F87171), // Red with opacity
      Color(0x80A78BFA), // Purple with opacity
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // MARK: - Spectrum Analyzer Gradients

  /// Spectrum gradient (frequency-based hue)
  static LinearGradient spectrumGradient(int bands) {
    final colors = List.generate(bands, (i) {
      final hue = 220.0 + (80.0 * i / bands); // 220 (blue) to 300 (purple)
      return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    });
    return LinearGradient(
      colors: colors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  // MARK: - UI Gradients

  /// Card background gradient
  static const LinearGradient cardBackground = LinearGradient(
    colors: [
      CartoMixColors.bgSecondary,
      Color(0x80252525), // bgTertiary with opacity
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Glow effect gradient
  static RadialGradient glow(Color color, {double opacity = 0.3}) {
    return RadialGradient(
      colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0),
      ],
      radius: 0.5,
    );
  }

  /// Playhead glow gradient
  static RadialGradient playheadGlow = RadialGradient(
    colors: [
      CartoMixColors.accent.withValues(alpha: 0.4),
      CartoMixColors.accent.withValues(alpha: 0),
    ],
    radius: 0.8,
  );

  /// Waveform vertical gradient (for single-color bars with depth)
  static LinearGradient waveformBar(Color color) {
    return LinearGradient(
      colors: [
        color.withValues(alpha: 0.9),
        color,
        color.withValues(alpha: 0.7),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  // MARK: - Score Bar Gradients

  /// Vibe/similarity score bar (purple)
  static const LinearGradient vibeBar = LinearGradient(
    colors: [
      Color(0xFFA78BFA),
      Color(0xFF8B5CF6),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Tempo score bar (blue)
  static const LinearGradient tempoBar = LinearGradient(
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Key score bar (green)
  static const LinearGradient keyBar = LinearGradient(
    colors: [
      Color(0xFF22C55E),
      Color(0xFF16A34A),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Energy score bar (yellow/orange)
  static const LinearGradient energyBar = LinearGradient(
    colors: [
      Color(0xFFEAB308),
      Color(0xFFCA8A04),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
