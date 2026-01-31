import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';

/// Track item in the set builder list
/// Shows track info with position number, drag handle, and remove button
class SetTrackItem extends StatelessWidget {
  final Track track;
  final int position; // 1-based position
  final bool isSelected;
  final bool isDragging;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const SetTrackItem({
    super.key,
    required this.track,
    required this.position,
    this.isSelected = false,
    this.isDragging = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDragging
          ? CartoMixColors.bgElevated
          : isSelected
              ? CartoMixColors.selection
              : Colors.transparent,
      elevation: isDragging ? 8 : 0,
      borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CartoMixSpacing.md,
            vertical: CartoMixSpacing.sm,
          ),
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: CartoMixColors.primary.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
                )
              : null,
          child: Row(
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: position - 1,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.all(CartoMixSpacing.xs),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: CartoMixColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CartoMixSpacing.sm),
              // Position number
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: track.energyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                  border: Border.all(color: track.energyColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: CartoMixTypography.badge.copyWith(
                      color: track.energyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CartoMixSpacing.md),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: CartoMixTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: CartoMixSpacing.xxs),
                    Text(
                      track.artist,
                      style: CartoMixTypography.caption.copyWith(
                        color: CartoMixColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CartoMixSpacing.md),
              // Metadata badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BPM
                  if (track.bpm != null)
                    _MetadataBadge(
                      value: track.bpmFormatted ?? '-',
                      color: CartoMixColors.primary,
                      width: 52,
                    ),
                  const SizedBox(width: CartoMixSpacing.sm),
                  // Key
                  if (track.key != null)
                    _MetadataBadge(
                      value: track.key ?? '-',
                      color: track.keyColor,
                      width: 40,
                    ),
                  const SizedBox(width: CartoMixSpacing.sm),
                  // Energy
                  _MetadataBadge(
                    value: '${track.energy ?? 5}',
                    color: track.energyColor,
                    width: 28,
                  ),
                  const SizedBox(width: CartoMixSpacing.sm),
                  // Duration
                  if (track.durationFormatted != null)
                    Text(
                      track.durationFormatted!,
                      style: CartoMixTypography.caption.copyWith(
                        color: CartoMixColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: CartoMixSpacing.md),
              // Remove button
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                color: CartoMixColors.textMuted,
                padding: const EdgeInsets.all(CartoMixSpacing.xs),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Remove from set',
                hoverColor: CartoMixColors.error.withValues(alpha: 0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  final String value;
  final Color color;
  final double width;

  const _MetadataBadge({
    required this.value,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: CartoMixSpacing.xs,
        vertical: CartoMixSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
      ),
      child: Text(
        value,
        style: CartoMixTypography.badgeSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
