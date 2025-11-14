import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformUtils {
  // Check if running on desktop platforms
  static bool get isDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  // Check if running on mobile platforms
  static bool get isMobile {
    return Platform.isAndroid || Platform.isIOS;
  }
  
  // Check specific platforms
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => kIsWeb;
  
  // Get platform-specific configurations
  static double get defaultWindowWidth {
    if (isDesktop) {
      return 1200.0;
    }
    return 390.0; // Mobile width
  }
  
  static double get defaultWindowHeight {
    if (isDesktop) {
      return 800.0;
    }
    return 844.0; // Mobile height
  }
  
  // Desktop-specific UI configurations
  static EdgeInsets get desktopPadding {
    return const EdgeInsets.all(24.0);
  }
  
  static EdgeInsets get mobilePadding {
    return const EdgeInsets.all(16.0);
  }
  
  static EdgeInsets get platformPadding {
    return isDesktop ? desktopPadding : mobilePadding;
  }
  
  // Font size adjustments for desktop
  static double adjustFontSize(double mobileSize) {
    if (isDesktop) {
      return mobileSize * 1.1; // Slightly larger fonts for desktop
    }
    return mobileSize;
  }
  
  // Icon size adjustments for desktop
  static double adjustIconSize(double mobileSize) {
    if (isDesktop) {
      return mobileSize * 1.2; // Slightly larger icons for desktop
    }
    return mobileSize;
  }
}
