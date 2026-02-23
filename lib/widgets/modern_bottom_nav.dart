import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// Ultra Modern bottom navigation bar - Performance optimized (No heavy animations)
class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<ModernNavItem> items;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    
    return Container(
      margin: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        0,
        responsive.horizontalPadding,
        responsive.horizontalPadding,
      ),
      height: responsive.bottomNavHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildNavItem(
              context: context,
              item: items[i],
              isActive: currentIndex == i,
              onTap: () => onTap(i),
            ),
            if (i < items.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required ModernNavItem item,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final responsive = ResponsiveHelper(context);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: EdgeInsets.only(
          top: isActive ? 0 : 15,
          bottom: 15,
        ),
        child: Container(
          width: responsive.bottomNavButtonSize,
          height: responsive.bottomNavButtonSize,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive 
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            color: isActive ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6),
            size: responsive.scale(24),
          ),
        ),
      ),
    );
  }
}

class ModernNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const ModernNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
