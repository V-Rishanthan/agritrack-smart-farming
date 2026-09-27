import 'package:flutter/material.dart';
import 'package:smart_farming/theme/app_colors.dart' show AppColors;

/// Reusable bottom navigation bar for AgriTrack.
///
/// Usage:
/// ```dart
/// int _currentIndex = 0;
///
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: AppBottomNavBar(
///     currentIndex: _currentIndex,
///     onTap: (index) {
///       setState(() => _currentIndex = index);
///       // or navigate: context.go(AppBottomNavBar.items[index].route);
///     },
///   ),
/// )
/// ```
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Central place to define nav items — add/remove/reorder tabs here only.
  static const List<BottomNavItem> items = [
    BottomNavItem(icon: Icons.grid_view_rounded, label: 'Home', route: '/home'),
    BottomNavItem(
      icon: Icons.groups_outlined,
      label: 'Owners',
      route: '/owners',
    ),
    BottomNavItem(
      icon: Icons.local_shipping_outlined,
      label: 'Driver',
      route: '/driver',
    ),
    BottomNavItem(
      icon: Icons.receipt_long_outlined,
      label: 'Expenses',
      route: '/expenses',
    ),
    BottomNavItem(
      icon: Icons.show_chart_rounded,
      label: 'Analysis',
      route: '/analysis',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            return _NavButton(
              item: items[index],
              isSelected: isSelected,
              onTap: () => onTap(index),
            );
          }),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isSelected
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: AppColors.navInactive, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.navInactive,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Data model for a single bottom nav tab.
class BottomNavItem {
  final IconData icon;
  final String label;
  final String route;

  const BottomNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
