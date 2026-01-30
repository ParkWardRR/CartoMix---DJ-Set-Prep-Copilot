import 'package:flutter/material.dart';
import 'colors.dart';

/// CartoMix typography system
/// Uses system fonts with Apple SF Pro as primary
class CartoMixTypography {
  CartoMixTypography._();

  // MARK: - Font Family
  static const String fontFamily = '.SF Pro Display';

  // MARK: - Font Sizes
  static const double fontSizeXs = 10.0;
  static const double fontSizeSm = 11.0;
  static const double fontSizeMd = 12.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeLg = 15.0;
  static const double fontSizeXl = 17.0;
  static const double fontSizeXxl = 22.0;
  static const double fontSizeTitle = 28.0;

  // MARK: - Text Styles

  /// Large title - 28px bold
  static const TextStyle largeTitle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: CartoMixColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Title - 22px semibold
  static const TextStyle title = TextStyle(
    fontSize: fontSizeXxl,
    fontWeight: FontWeight.w600,
    color: CartoMixColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Headline - 17px semibold
  static const TextStyle headline = TextStyle(
    fontSize: fontSizeXl,
    fontWeight: FontWeight.w600,
    color: CartoMixColors.textPrimary,
  );

  /// Body - 15px regular
  static const TextStyle body = TextStyle(
    fontSize: fontSizeLg,
    fontWeight: FontWeight.normal,
    color: CartoMixColors.textPrimary,
    height: 1.5,
  );

  /// Body small - 14px regular
  static const TextStyle bodySmall = TextStyle(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.normal,
    color: CartoMixColors.textPrimary,
    height: 1.5,
  );

  /// Caption - 12px medium
  static const TextStyle caption = TextStyle(
    fontSize: fontSizeMd,
    fontWeight: FontWeight.w500,
    color: CartoMixColors.textSecondary,
  );

  /// Badge - 11px semibold
  static const TextStyle badge = TextStyle(
    fontSize: fontSizeSm,
    fontWeight: FontWeight.w600,
    color: CartoMixColors.textPrimary,
  );

  /// Badge small - 10px semibold (extra small pills)
  static const TextStyle badgeSmall = TextStyle(
    fontSize: fontSizeXs,
    fontWeight: FontWeight.w600,
    color: CartoMixColors.textPrimary,
  );

  /// Mono - 13px medium monospace
  static const TextStyle mono = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    fontFamily: 'SF Mono',
    color: CartoMixColors.textPrimary,
  );

  /// Mono small - 11px medium monospace
  static const TextStyle monoSmall = TextStyle(
    fontSize: fontSizeSm,
    fontWeight: FontWeight.w500,
    fontFamily: 'SF Mono',
    color: CartoMixColors.textPrimary,
  );

  /// Label - 12px uppercase medium (for stats, axis labels)
  static TextStyle label = TextStyle(
    fontSize: fontSizeMd,
    fontWeight: FontWeight.w500,
    color: CartoMixColors.textMuted,
    letterSpacing: 0.5,
  );

  /// Track title in cards - 14px semibold
  static const TextStyle trackTitle = TextStyle(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.w600,
    color: CartoMixColors.textPrimary,
  );

  /// Track artist in cards - 12px regular
  static const TextStyle trackArtist = TextStyle(
    fontSize: fontSizeMd,
    fontWeight: FontWeight.normal,
    color: CartoMixColors.textSecondary,
  );

  /// Metadata values (BPM, Key, etc) - 12px medium
  static const TextStyle metadata = TextStyle(
    fontSize: fontSizeMd,
    fontWeight: FontWeight.w500,
    color: CartoMixColors.textSecondary,
  );
}
