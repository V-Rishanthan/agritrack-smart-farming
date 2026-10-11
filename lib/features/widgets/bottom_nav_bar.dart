import 'package:flutter/material.dart';
import 'package:smart_farming/theme/app_colors.dart';

/// Reusable, responsive bottom navigation bar for AgriTrack.
/// Built with full-width expanded touch targets to eliminate dead zones and lag.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Central place to define nav items — add/remove/reorder tabs here.
  static const List<BottomNavItem> items = [
    BottomNavItem(
      icon: Icons.grid_view_rounded,
      label: 'Home',
      route: '/home',
    ),
    BottomNavItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      label: 'Owners',
      route: '/owners',
    ),
    BottomNavItem(
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping_rounded,
      label: 'Driver',
      route: '/driver',
    ),
    BottomNavItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: 'Expenses',
      route: '/expenses',
    ),
    BottomNavItem(
      icon: Icons.show_chart_rounded,
      selectedIcon: Icons.show_chart_rounded,
      label: 'Analysis',
      route: '/analysis',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              return Expanded(
                child: _NavButton(
                  item: items[index],
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accentPink.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            constraints: const BoxConstraints(
              maxWidth: 110,
              minHeight: 40,
            ),
            padding: isSelected
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: isSelected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.selectedIcon ?? item.icon,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: AppColors.navInactive,
                        size: 20,
                      ),
                      const SizedBox(height: 3),
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.navInactive,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Data model for a single bottom nav tab.
class BottomNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String route;

  const BottomNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.route,
  });
}
