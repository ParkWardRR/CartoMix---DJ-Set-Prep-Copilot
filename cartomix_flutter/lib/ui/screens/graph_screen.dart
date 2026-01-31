import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Transition Graph screen for visualizing track relationships
class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Graph canvas (2/3)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildToolbar(),
              const Divider(height: 1),
              Expanded(
                child: _buildGraphCanvas(),
              ),
            ],
          ),
        ),
        // Sidebar (1/3)
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: _buildSidebar(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      color: CartoMixColors.bgSecondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Similarity threshold slider
            Text(
              'Min Score:',
              style: CartoMixTypography.caption,
            ),
            const SizedBox(width: CartoMixSpacing.sm),
            SizedBox(
              width: 120,
              child: Slider(
                value: 6.0,
                min: 0,
                max: 10,
                divisions: 20,
                label: '6.0',
                onChanged: (value) {},
              ),
            ),
            const SizedBox(width: CartoMixSpacing.md),
            // Show set only toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Checkbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: CartoMixSpacing.xs),
                Text(
                  'Set Only',
                  style: CartoMixTypography.caption,
                ),
              ],
            ),
            const SizedBox(width: CartoMixSpacing.lg),
            // Zoom controls
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 18),
              onPressed: () {},
              tooltip: 'Zoom Out',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in, size: 18),
              onPressed: () {},
              tooltip: 'Zoom In',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong, size: 18),
              onPressed: () {},
              tooltip: 'Reset View',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphCanvas() {
    return Container(
      color: CartoMixColors.bgPrimary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 64,
              color: CartoMixColors.textMuted,
            ),
            const SizedBox(height: CartoMixSpacing.md),
            Text(
              'No tracks to visualize',
              style: CartoMixTypography.headline.copyWith(
                color: CartoMixColors.textSecondary,
              ),
            ),
            const SizedBox(height: CartoMixSpacing.sm),
            Text(
              'Analyze tracks to see their relationships',
              style: CartoMixTypography.body.copyWith(
                color: CartoMixColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: CartoMixColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graph info
          Padding(
            padding: const EdgeInsets.all(CartoMixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Graph Info',
                  style: CartoMixTypography.badge.copyWith(
                    color: CartoMixColors.textSecondary,
                  ),
                ),
                const SizedBox(height: CartoMixSpacing.sm),
                _buildInfoRow('Nodes', '0'),
                _buildInfoRow('Edges', '0'),
                _buildInfoRow('Avg Score', '-'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Legend
          Padding(
            padding: const EdgeInsets.all(CartoMixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legend',
                  style: CartoMixTypography.badge.copyWith(
                    color: CartoMixColors.textSecondary,
                  ),
                ),
                const SizedBox(height: CartoMixSpacing.sm),
                _buildLegendItem(CartoMixColors.success, 'Score >= 8'),
                _buildLegendItem(CartoMixColors.primary, 'Score >= 6'),
                _buildLegendItem(CartoMixColors.textMuted, 'Score < 6'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Selected track (when node clicked)
          Expanded(
            child: Center(
              child: Text(
                'Click a node to view details',
                style: CartoMixTypography.caption.copyWith(
                  color: CartoMixColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CartoMixSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textMuted,
            ),
          ),
          Text(
            value,
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CartoMixSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: CartoMixSpacing.sm),
          Text(
            label,
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
