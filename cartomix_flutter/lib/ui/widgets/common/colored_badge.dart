import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// A colored pill/badge widget for displaying metadata values
class ColoredBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final bool small;

  const ColoredBadge({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = small
        ? const EdgeInsets.symmetric(
            horizontal: CartoMixSpacing.xs + 2,
            vertical: 1,
          )
        : const EdgeInsets.symmetric(
            horizontal: CartoMixSpacing.sm,
            vertical: CartoMixSpacing.xxs,
          );

    final style = small ? CartoMixTypography.badgeSmall : CartoMixTypography.badge;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: filled ? 0 : 0.3),
        ),
      ),
      child: Text(
        label,
        style: style.copyWith(
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

/// Status badge for analysis status
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'complete':
      case 'analyzed':
        color = CartoMixColors.statusAnalyzed;
        label = 'Analyzed';
        break;
      case 'analyzing':
        color = CartoMixColors.statusAnalyzing;
        label = 'Analyzing';
        break;
      case 'failed':
        color = CartoMixColors.statusFailed;
        label = 'Failed';
        break;
      default:
        color = CartoMixColors.statusPending;
        label = 'Pending';
    }

    return ColoredBadge(label: label, color: color, small: true);
  }
}

/// BPM badge
class BpmBadge extends StatelessWidget {
  final double? bpm;

  const BpmBadge({super.key, this.bpm});

  @override
  Widget build(BuildContext context) {
    if (bpm == null) return const SizedBox.shrink();
    return ColoredBadge(
      label: bpm!.toStringAsFixed(0),
      color: CartoMixColors.primary,
      small: true,
    );
  }
}

/// Key badge with Camelot color
class KeyBadge extends StatelessWidget {
  final String? keyValue;

  const KeyBadge({super.key, this.keyValue});

  @override
  Widget build(BuildContext context) {
    if (keyValue == null || keyValue!.isEmpty) return const SizedBox.shrink();
    return ColoredBadge(
      label: keyValue!,
      color: CartoMixColors.colorForKey(keyValue!),
      small: true,
    );
  }
}

/// Energy badge with energy level color
class EnergyBadge extends StatelessWidget {
  final int? energy;

  const EnergyBadge({super.key, this.energy});

  @override
  Widget build(BuildContext context) {
    if (energy == null) return const SizedBox.shrink();
    return ColoredBadge(
      label: '$energy',
      color: CartoMixColors.colorForEnergy(energy!),
      small: true,
    );
  }
}

/// Duration badge
class DurationBadge extends StatelessWidget {
  final String? duration;

  const DurationBadge({super.key, this.duration});

  @override
  Widget build(BuildContext context) {
    if (duration == null) return const SizedBox.shrink();
    return ColoredBadge(
      label: duration!,
      color: CartoMixColors.accent,
      small: true,
    );
  }
}

/// Score badge for transition scores
class ScoreBadge extends StatelessWidget {
  final double score;

  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return ColoredBadge(
      label: score.toStringAsFixed(1),
      color: CartoMixColors.colorForTransitionScore(score),
      filled: true,
      small: true,
    );
  }
}
