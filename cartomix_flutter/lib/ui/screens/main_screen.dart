import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';
import 'library_screen.dart';
import 'set_builder_screen.dart';
import 'graph_screen.dart';
import 'settings_screen.dart';

/// Main application screen with navigation
/// Pro-level DJ software UI with custom navigation rail
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();
  bool _showShortcutsOverlay = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Keyboard shortcut handler
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final bool isCmd = HardwareKeyboard.instance.isMetaPressed;
    final bool isShift = HardwareKeyboard.instance.isShiftPressed;

    // Cmd+1-4: Navigate between screens
    if (isCmd && !isShift) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        setState(() => _selectedIndex = 0);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        setState(() => _selectedIndex = 1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        setState(() => _selectedIndex = 2);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit4) {
        setState(() => _selectedIndex = 3);
        return KeyEventResult.handled;
      }
    }

    // Cmd+/ or ?: Show keyboard shortcuts
    if ((isCmd && event.logicalKey == LogicalKeyboardKey.slash) ||
        (isShift && event.logicalKey == LogicalKeyboardKey.slash)) {
      setState(() => _showShortcutsOverlay = !_showShortcutsOverlay);
      return KeyEventResult.handled;
    }

    // Escape: Close overlays
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_showShortcutsOverlay) {
        setState(() => _showShortcutsOverlay = false);
        return KeyEventResult.handled;
      }
    }

    // Tab: Cycle through screens
    if (event.logicalKey == LogicalKeyboardKey.tab && !isCmd) {
      setState(() {
        if (isShift) {
          _selectedIndex = (_selectedIndex - 1 + 4) % 4;
        } else {
          _selectedIndex = (_selectedIndex + 1) % 4;
        }
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  static const _navItems = [
    _NavItem(
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      label: 'Library',
    ),
    _NavItem(
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      label: 'Set Builder',
    ),
    _NavItem(
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
      label: 'Graph',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          Scaffold(
            key: const Key('main.screen'),
            body: Column(
              children: [
                // Custom title bar for macOS
                _buildTitleBar(),
                // Main content
                Expanded(
                  child: Row(
                    children: [
                      // Custom navigation rail (more control than NavigationRail)
                      _buildNavRail(),
                      // Vertical divider
                      Container(
                        width: 1,
                        color: CartoMixColors.border,
                      ),
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
          ),
          // Keyboard shortcuts overlay
          if (_showShortcutsOverlay) _buildShortcutsOverlay(),
        ],
      ),
    );
  }

  Widget _buildShortcutsOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showShortcutsOverlay = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(CartoMixSpacing.xl),
              decoration: BoxDecoration(
                color: CartoMixColors.bgElevated,
                borderRadius: BorderRadius.circular(CartoMixSpacing.radiusLg),
                border: Border.all(color: CartoMixColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.keyboard,
                        color: CartoMixColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: CartoMixSpacing.sm),
                      Text(
                        'Keyboard Shortcuts',
                        style: CartoMixTypography.headline.copyWith(
                          color: CartoMixColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CartoMixSpacing.lg),
                  _buildShortcutSection('Navigation', [
                    ('⌘1', 'Library'),
                    ('⌘2', 'Set Builder'),
                    ('⌘3', 'Graph'),
                    ('⌘4', 'Settings'),
                    ('Tab', 'Next screen'),
                    ('⇧Tab', 'Previous screen'),
                  ]),
                  const SizedBox(height: CartoMixSpacing.md),
                  _buildShortcutSection('General', [
                    ('⌘/', 'Show shortcuts'),
                    ('Esc', 'Close dialog'),
                  ]),
                  const SizedBox(height: CartoMixSpacing.lg),
                  Center(
                    child: Text(
                      'Press Esc or click anywhere to close',
                      style: CartoMixTypography.caption.copyWith(
                        color: CartoMixColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutSection(String title, List<(String, String)> shortcuts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CartoMixTypography.badge.copyWith(
            color: CartoMixColors.textSecondary,
          ),
        ),
        const SizedBox(height: CartoMixSpacing.sm),
        ...shortcuts.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: CartoMixSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(
                  horizontal: CartoMixSpacing.sm,
                  vertical: CartoMixSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: CartoMixColors.bgTertiary,
                  borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                  border: Border.all(color: CartoMixColors.border),
                ),
                child: Text(
                  s.$1,
                  style: CartoMixTypography.badge.copyWith(
                    color: CartoMixColors.textPrimary,
                    fontFamily: 'SF Mono',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: CartoMixSpacing.md),
              Text(
                s.$2,
                style: CartoMixTypography.body.copyWith(
                  color: CartoMixColors.textSecondary,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTitleBar() {
    return Container(
      key: const Key('main.titleBar'),
      height: 28,
      color: CartoMixColors.bgPrimary,
      child: Row(
        children: [
          // Window buttons area (macOS - 78px for traffic lights)
          const SizedBox(width: 78),
          // Draggable area for window movement
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

  Widget _buildNavRail() {
    return Container(
      key: const Key('main.navRail'),
      width: 80,
      color: CartoMixColors.bgSecondary,
      child: Column(
        children: [
          // Logo at top
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CartoMixSpacing.lg),
            child: _buildLogo(),
          ),
          const SizedBox(height: CartoMixSpacing.md),
          // Navigation items
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < _navItems.length; i++)
                  _buildNavItem(_navItems[i], i),
              ],
            ),
          ),
          // Bottom indicator (optional future use)
          const SizedBox(height: CartoMixSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index) {
    final isSelected = _selectedIndex == index;
    final shortcut = '⌘${index + 1}';

    return Tooltip(
      message: '${item.label} ($shortcut)',
      preferBelow: false,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: CartoMixSpacing.md,
            horizontal: CartoMixSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? CartoMixColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? CartoMixColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 22,
                color: isSelected
                    ? CartoMixColors.primary
                    : CartoMixColors.textSecondary,
              ),
              const SizedBox(height: CartoMixSpacing.xxs),
              Text(
                item.label,
                style: CartoMixTypography.badgeSmall.copyWith(
                  color: isSelected
                      ? CartoMixColors.textPrimary
                      : CartoMixColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
            boxShadow: [
              BoxShadow(
                color: CartoMixColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
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
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      key: const Key('main.content'),
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
      key: const Key('main.footer'),
      height: 24,
      color: CartoMixColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: CartoMixSpacing.md),
      child: Row(
        children: [
          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CartoMixSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: CartoMixColors.bgTertiary,
              borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
            ),
            child: Text(
              'v0.13.0',
              style: CartoMixTypography.badgeSmall.copyWith(
                color: CartoMixColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: CartoMixSpacing.md),
          // Keyboard shortcuts hint
          GestureDetector(
            onTap: () => setState(() => _showShortcutsOverlay = true),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CartoMixSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: CartoMixColors.bgTertiary,
                  borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard,
                      size: 12,
                      color: CartoMixColors.textMuted,
                    ),
                    const SizedBox(width: CartoMixSpacing.xxs),
                    Text(
                      '⌘/',
                      style: CartoMixTypography.badgeSmall.copyWith(
                        color: CartoMixColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Spacer
          const Spacer(),
          // Connection status indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: CartoMixColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CartoMixColors.success.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
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

/// Navigation item data class
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
