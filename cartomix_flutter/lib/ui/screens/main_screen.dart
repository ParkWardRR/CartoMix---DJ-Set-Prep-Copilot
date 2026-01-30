import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import 'library_screen.dart';
import 'set_builder_screen.dart';
import 'graph_screen.dart';
import 'settings_screen.dart';

/// Main application screen with navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.queue_music_outlined),
      selectedIcon: Icon(Icons.queue_music),
      label: 'Set Builder',
    ),
    NavigationDestination(
      icon: Icon(Icons.hub_outlined),
      selectedIcon: Icon(Icons.hub),
      label: 'Graph',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom title bar for macOS
          _buildTitleBar(),
          // Main content
          Expanded(
            child: Row(
              children: [
                // Navigation rail
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: CartoMixColors.bgSecondary,
                  indicatorColor: CartoMixColors.primary.withValues(alpha: 0.2),
                  destinations: _destinations
                      .map((d) => NavigationRailDestination(
                            icon: d.icon,
                            selectedIcon: d.selectedIcon,
                            label: Text(d.label),
                          ))
                      .toList(),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: CartoMixSpacing.lg),
                    child: _buildLogo(),
                  ),
                ),
                // Vertical divider
                const VerticalDivider(width: 1),
                // Content area
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 28,
      color: CartoMixColors.bgPrimary,
      child: Row(
        children: [
          // Window buttons area (macOS)
          const SizedBox(width: 78),
          // Draggable area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) {},
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: CartoMixGradients.waveform,
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.xs),
        Text(
          'CartoMix',
          style: CartoMixTypography.badgeSmall.copyWith(
            color: CartoMixColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        LibraryScreen(),
        SetBuilderScreen(),
        GraphScreen(),
        SettingsScreen(),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 24,
      color: CartoMixColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: CartoMixSpacing.md),
      child: Row(
        children: [
          // Version
          Text(
            'v0.4.0-alpha',
            style: CartoMixTypography.badgeSmall.copyWith(
              color: CartoMixColors.textMuted,
            ),
          ),
          const Spacer(),
          // Connection status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: CartoMixColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: CartoMixSpacing.xs),
              Text(
                'Native Backend Connected',
                style: CartoMixTypography.badgeSmall.copyWith(
                  color: CartoMixColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
