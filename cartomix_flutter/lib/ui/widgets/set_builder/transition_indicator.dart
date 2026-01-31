import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';

/// Transition indicator between two tracks in the set builder
/// Shows BPM change, key compatibility, and energy flow
class TransitionIndicator extends StatelessWidget {
  final Track fromTrack;
  final Track toTrack;
  final VoidCallback? onTap;

  const TransitionIndicator({
    super.key,
    required this.fromTrack,
    required this.toTrack,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final transition = _calculateTransition();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CartoMixSpacing.lg,
          vertical: CartoMixSpacing.sm,
        ),
        child: Row(
          children: [
            const SizedBox(width: 40), // Align with track numbers
            // Transition line with arrow
            _buildTransitionLine(transition),
            const SizedBox(width: CartoMixSpacing.md),
            // Transition details
            Expanded(
              child: _buildTransitionDetails(transition),
            ),
            // Score badge
            _buildScoreBadge(transition),
          ],
        ),
      ),
    );
  }

  _TransitionData _calculateTransition() {
    final fromBpm = fromTrack.bpm;
    final toBpm = toTrack.bpm;
    final fromKey = fromTrack.key;
    final toKey = toTrack.key;
    final fromEnergy = fromTrack.energy ?? 5;
    final toEnergy = toTrack.energy ?? 5;

    // Calculate BPM change
    double? bpmChange;
    String bpmCompatibility = 'unknown';
    if (fromBpm != null && toBpm != null) {
      bpmChange = toBpm - fromBpm;
      final bpmDiff = bpmChange.abs();
      if (bpmDiff <= 3) {
        bpmCompatibility = 'perfect';
      } else if (bpmDiff <= 6) {
        bpmCompatibility = 'good';
      } else if (bpmDiff <= 10) {
        bpmCompatibility = 'fair';
      } else {
        bpmCompatibility = 'poor';
      }
    }

    // Calculate key compatibility
    String keyCompatibility = 'unknown';
    if (fromKey != null && toKey != null) {
      keyCompatibility = _calculateKeyCompatibility(fromKey, toKey);
    }

    // Calculate energy flow
    final energyChange = toEnergy - fromEnergy;
    String energyFlow;
    if (energyChange > 2) {
      energyFlow = 'big_jump';
    } else if (energyChange > 0) {
      energyFlow = 'building';
    } else if (energyChange < -2) {
      energyFlow = 'big_drop';
    } else if (energyChange < 0) {
      energyFlow = 'cooling';
    } else {
      energyFlow = 'steady';
    }

    // Calculate overall score
    double score = 0;
    int factors = 0;

    if (bpmCompatibility != 'unknown') {
      factors++;
      switch (bpmCompatibility) {
        case 'perfect':
          score += 100;
          break;
        case 'good':
          score += 80;
          break;
        case 'fair':
          score += 60;
          break;
        case 'poor':
          score += 30;
          break;
      }
    }

    if (keyCompatibility != 'unknown') {
      factors++;
      switch (keyCompatibility) {
        case 'same':
          score += 100;
          break;
        case 'perfect':
          score += 95;
          break;
        case 'harmonic':
          score += 85;
          break;
        case 'relative':
          score += 75;
          break;
        case 'parallel':
          score += 65;
          break;
        default:
          score += 40;
      }
    }

    final overallScore = factors > 0 ? score / factors : null;

    return _TransitionData(
      bpmChange: bpmChange,
      bpmCompatibility: bpmCompatibility,
      keyCompatibility: keyCompatibility,
      energyChange: energyChange,
      energyFlow: energyFlow,
      overallScore: overallScore,
    );
  }

  String _calculateKeyCompatibility(String fromKey, String toKey) {
    if (fromKey == toKey) return 'same';

    // Parse Camelot keys
    final fromMatch = RegExp(r'^(\d+)([AB])$').firstMatch(fromKey.toUpperCase());
    final toMatch = RegExp(r'^(\d+)([AB])$').firstMatch(toKey.toUpperCase());

    if (fromMatch == null || toMatch == null) return 'unknown';

    final fromNum = int.parse(fromMatch.group(1)!);
    final toNum = int.parse(toMatch.group(1)!);
    final fromLetter = fromMatch.group(2)!;
    final toLetter = toMatch.group(2)!;

    // Same position, different letter (parallel)
    if (fromNum == toNum && fromLetter != toLetter) return 'parallel';

    // Adjacent positions, same letter (perfect/harmonic)
    if (fromLetter == toLetter) {
      final diff = (toNum - fromNum).abs();
      if (diff == 1 || diff == 11) return 'perfect'; // +1 or -1 on the wheel
    }

    // Same number, adjacent letters (relative)
    if (fromNum == toNum) return 'relative';

    return 'other';
  }

  Widget _buildTransitionLine(_TransitionData transition) {
    final color = _getScoreColor(transition.overallScore);

    return SizedBox(
      width: 24,
      height: 32,
      child: CustomPaint(
        painter: _TransitionLinePainter(
          color: color,
          energyChange: transition.energyChange,
        ),
      ),
    );
  }

  Widget _buildTransitionDetails(_TransitionData transition) {
    final hints = <Widget>[];

    // BPM hint
    if (transition.bpmChange != null) {
      final bpmSign = transition.bpmChange! >= 0 ? '+' : '';
      hints.add(_buildHint(
        Icons.speed,
        '$bpmSign${transition.bpmChange!.toStringAsFixed(0)} BPM',
        _getBpmColor(transition.bpmCompatibility),
      ));
    }

    // Key hint
    if (transition.keyCompatibility != 'unknown') {
      hints.add(_buildHint(
        Icons.music_note,
        _getKeyLabel(transition.keyCompatibility),
        _getKeyColor(transition.keyCompatibility),
      ));
    }

    // Energy hint
    hints.add(_buildHint(
      _getEnergyIcon(transition.energyFlow),
      _getEnergyLabel(transition.energyFlow),
      _getEnergyColor(transition.energyFlow),
    ));

    return Wrap(
      spacing: CartoMixSpacing.md,
      runSpacing: CartoMixSpacing.xxs,
      children: hints,
    );
  }

  Widget _buildHint(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: CartoMixTypography.badgeSmall.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildScoreBadge(_TransitionData transition) {
    if (transition.overallScore == null) {
      return const SizedBox(width: 48);
    }

    final score = transition.overallScore!.round();
    final color = _getScoreColor(transition.overallScore);

    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(
        horizontal: CartoMixSpacing.sm,
        vertical: CartoMixSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$score%',
        style: CartoMixTypography.badgeSmall.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getScoreColor(double? score) {
    if (score == null) return CartoMixColors.textMuted;
    if (score >= 85) return CartoMixColors.success;
    if (score >= 70) return CartoMixColors.primary;
    if (score >= 50) return CartoMixColors.warning;
    return CartoMixColors.error;
  }

  Color _getBpmColor(String compatibility) {
    switch (compatibility) {
      case 'perfect':
        return CartoMixColors.success;
      case 'good':
        return CartoMixColors.primary;
      case 'fair':
        return CartoMixColors.warning;
      case 'poor':
        return CartoMixColors.error;
      default:
        return CartoMixColors.textMuted;
    }
  }

  Color _getKeyColor(String compatibility) {
    switch (compatibility) {
      case 'same':
      case 'perfect':
        return CartoMixColors.success;
      case 'harmonic':
      case 'relative':
        return CartoMixColors.primary;
      case 'parallel':
        return CartoMixColors.warning;
      default:
        return CartoMixColors.textMuted;
    }
  }

  String _getKeyLabel(String compatibility) {
    switch (compatibility) {
      case 'same':
        return 'Same key';
      case 'perfect':
        return 'Perfect';
      case 'harmonic':
        return 'Harmonic';
      case 'relative':
        return 'Relative';
      case 'parallel':
        return 'Parallel';
      default:
        return 'Key clash';
    }
  }

  IconData _getEnergyIcon(String flow) {
    switch (flow) {
      case 'big_jump':
        return Icons.trending_up;
      case 'building':
        return Icons.north_east;
      case 'big_drop':
        return Icons.trending_down;
      case 'cooling':
        return Icons.south_east;
      default:
        return Icons.trending_flat;
    }
  }

  String _getEnergyLabel(String flow) {
    switch (flow) {
      case 'big_jump':
        return 'Energy jump';
      case 'building':
        return 'Building';
      case 'big_drop':
        return 'Energy drop';
      case 'cooling':
        return 'Cooling';
      default:
        return 'Steady';
    }
  }

  Color _getEnergyColor(String flow) {
    switch (flow) {
      case 'big_jump':
        return CartoMixColors.energyPeak;
      case 'building':
        return CartoMixColors.energyHigh;
      case 'big_drop':
        return CartoMixColors.energyLow;
      case 'cooling':
        return CartoMixColors.energyMid;
      default:
        return CartoMixColors.primary;
    }
  }
}

class _TransitionData {
  final double? bpmChange;
  final String bpmCompatibility;
  final String keyCompatibility;
  final int energyChange;
  final String energyFlow;
  final double? overallScore;

  const _TransitionData({
    required this.bpmChange,
    required this.bpmCompatibility,
    required this.keyCompatibility,
    required this.energyChange,
    required this.energyFlow,
    required this.overallScore,
  });
}

class _TransitionLinePainter extends CustomPainter {
  final Color color;
  final int energyChange;

  _TransitionLinePainter({
    required this.color,
    required this.energyChange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midX = size.width / 2;

    // Draw vertical line with slight curve based on energy change
    path.moveTo(midX, 0);

    if (energyChange > 0) {
      // Energy increasing - curve right
      path.quadraticBezierTo(midX + 6, size.height / 2, midX, size.height);
    } else if (energyChange < 0) {
      // Energy decreasing - curve left
      path.quadraticBezierTo(midX - 6, size.height / 2, midX, size.height);
    } else {
      // Steady - straight line
      path.lineTo(midX, size.height);
    }

    canvas.drawPath(path, paint);

    // Draw arrow at bottom
    final arrowPath = Path();
    arrowPath.moveTo(midX - 4, size.height - 6);
    arrowPath.lineTo(midX, size.height);
    arrowPath.lineTo(midX + 4, size.height - 6);

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_TransitionLinePainter oldDelegate) {
    return color != oldDelegate.color || energyChange != oldDelegate.energyChange;
  }
}
