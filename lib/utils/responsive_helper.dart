import 'package:flutter/material.dart';

/// Responsive helper for different screen sizes
class ResponsiveHelper {
  final BuildContext context;
  
  ResponsiveHelper(this.context);
  
  /// Get screen width
  double get width => MediaQuery.of(context).size.width;
  
  /// Get screen height
  double get height => MediaQuery.of(context).size.height;
  
  /// Check if device is small (width < 360)
  bool get isSmallDevice => width < 360;
  
  /// Check if device is medium (360 <= width < 400)
  bool get isMediumDevice => width >= 360 && width < 400;
  
  /// Check if device is large (width >= 400)
  bool get isLargeDevice => width >= 400;
  
  /// Get responsive value based on screen size
  T responsive<T>({
    required T small,
    required T medium,
    required T large,
  }) {
    if (isSmallDevice) return small;
    if (isMediumDevice) return medium;
    return large;
  }
  
  /// Get responsive double value
  double responsiveValue({
    required double small,
    required double medium,
    required double large,
  }) {
    if (isSmallDevice) return small;
    if (isMediumDevice) return medium;
    return large;
  }
  
  /// Scale value based on screen width (base: 375)
  double scale(double value) {
    return value * (width / 375);
  }
  
  /// Get horizontal padding
  double get horizontalPadding => responsiveValue(
    small: 16,
    medium: 20,
    large: 24,
  );
  
  /// Get vertical spacing
  double get verticalSpacing => responsiveValue(
    small: 16,
    medium: 20,
    large: 24,
  );
  
  /// Connection button size
  double get connectionButtonSize => responsiveValue(
    small: 120,
    medium: 130,
    large: 140,
  );
  
  /// Connection button icon size
  double get connectionButtonIconSize => responsiveValue(
    small: 34,
    medium: 37,
    large: 40,
  );
  
  /// Header font size
  double get headerFontSize => responsiveValue(
    small: 18,
    medium: 19,
    large: 20,
  );
  
  /// Timer font size
  double get timerFontSize => responsiveValue(
    small: 16,
    medium: 17,
    large: 18,
  );
  
  /// Stats value font size
  double get statsValueFontSize => responsiveValue(
    small: 12,
    medium: 13,
    large: 14,
  );
  
  /// Stats label font size
  double get statsLabelFontSize => responsiveValue(
    small: 9,
    medium: 9.5,
    large: 10,
  );
  
  /// Stats icon size
  double get statsIconSize => responsiveValue(
    small: 11,
    medium: 12,
    large: 13,
  );
  
  /// Server card icon size
  double get serverIconSize => responsiveValue(
    small: 42,
    medium: 45,
    large: 48,
  );
  
  /// Server card padding
  double get serverCardPadding => responsiveValue(
    small: 12,
    medium: 13,
    large: 14,
  );
  
  /// Tool card icon size
  double get toolIconSize => responsiveValue(
    small: 24,
    medium: 26,
    large: 28,
  );
  
  /// Tool card padding
  double get toolCardPadding => responsiveValue(
    small: 16,
    medium: 18,
    large: 20,
  );
  
  /// Bottom nav height
  double get bottomNavHeight => responsiveValue(
    small: 75,
    medium: 78,
    large: 82,
  );
  
  /// Bottom nav button size
  double get bottomNavButtonSize => responsiveValue(
    small: 48,
    medium: 50,
    large: 52,
  );
  
  /// Page title font size
  double get pageTitleFontSize => responsiveValue(
    small: 24,
    medium: 26,
    large: 28,
  );
  
  /// About logo size
  double get aboutLogoSize => responsiveValue(
    small: 70,
    medium: 75,
    large: 80,
  );
  
  /// About title font size
  double get aboutTitleFontSize => responsiveValue(
    small: 24,
    medium: 26,
    large: 28,
  );
}
