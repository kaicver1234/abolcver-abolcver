import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

class DesktopLayout extends StatelessWidget {
  final Widget child;
  final bool showSidebar;
  final Widget? sidebar;
  final String? title;

  const DesktopLayout({
    Key? key,
    required this.child,
    this.showSidebar = false,
    this.sidebar,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.isDesktop) {
      return child;
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar for desktop
          if (showSidebar && sidebar != null) 
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: sidebar!,
            ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Title bar for desktop
                if (title != null)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        // Window controls could be added here for custom title bar
                      ],
                    ),
                  ),
                
                // Main content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DesktopCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const DesktopCard({
    Key? key,
    required this.child,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? PlatformUtils.platformPadding,
      margin: PlatformUtils.isDesktop 
        ? const EdgeInsets.all(12.0)
        : const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(PlatformUtils.isDesktop ? 12.0 : 8.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: PlatformUtils.isDesktop ? 10.0 : 6.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    int columns = crossAxisCount ?? _calculateColumns(screenWidth);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio ?? 1.0,
        crossAxisSpacing: crossAxisSpacing ?? 16.0,
        mainAxisSpacing: mainAxisSpacing ?? 16.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
  
  int _calculateColumns(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
