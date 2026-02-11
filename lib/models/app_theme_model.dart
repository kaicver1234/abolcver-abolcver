class AppThemeModel {
  final String id;
  final String name;
  final String nameEn;
  final String nameFa;
  final String emoji;
  final ThemeColors colors;

  AppThemeModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameFa,
    required this.emoji,
    required this.colors,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'nameFa': nameFa,
    'emoji': emoji,
  };

  factory AppThemeModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return AppThemeModel(
      id: id,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      nameFa: json['nameFa'] as String,
      emoji: json['emoji'] as String,
      colors: _getThemeColors(id),
    );
  }

  static ThemeColors _getThemeColors(String id) {
    switch (id) {
      case 'default':
        return ThemeColors.defaultTheme();
      case 'ocean':
        return ThemeColors.oceanTheme();
      case 'sunset':
        return ThemeColors.sunsetTheme();
      case 'forest':
        return ThemeColors.forestTheme();
      default:
        return ThemeColors.defaultTheme();
    }
  }
}

class ThemeColors {
  // Background colors
  final int backgroundColor;
  final int surfaceColor;
  final int cardColor;
  
  // Primary colors
  final int primaryColor;
  final int secondaryColor;
  final int accentColor;
  
  // Text colors
  final int textPrimaryColor;
  final int textSecondaryColor;
  
  // Status colors
  final int successColor;
  final int errorColor;
  final int warningColor;
  
  // Special colors
  final int timerColor;
  final int downloadColor;
  final int uploadColor;
  
  // UI elements
  final int borderColor;
  final int dividerColor;
  final double backgroundOpacity;
  final double surfaceOpacity;
  final double cardOpacity;

  ThemeColors({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.timerColor,
    required this.downloadColor,
    required this.uploadColor,
    required this.borderColor,
    required this.dividerColor,
    this.backgroundOpacity = 1.0,
    this.surfaceOpacity = 0.05,
    this.cardOpacity = 0.08,
  });

  // Dark Green Theme (Default) - Fresh & Modern
  factory ThemeColors.defaultTheme() => ThemeColors(
    backgroundColor: 0xFF050505,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFF1a1a1a,
    primaryColor: 0xFF10b981,
    secondaryColor: 0xFF34d399,
    accentColor: 0xFF6ee7b7,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFFFFFFF,
    successColor: 0xFF10b981,
    errorColor: 0xFFef4444,
    warningColor: 0xFFfbbf24,
    timerColor: 0xFF10b981,
    downloadColor: 0xFF10b981,
    uploadColor: 0xFF34d399,
    borderColor: 0xFFFFFFFF,
    dividerColor: 0xFFFFFFFF,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.05,
    cardOpacity: 1.0,
  );

  // Dark Blue Theme - Professional & Calm
  factory ThemeColors.oceanTheme() => ThemeColors(
    backgroundColor: 0xFF050510,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFF1a1a1a,
    primaryColor: 0xFF3b82f6,
    secondaryColor: 0xFF60a5fa,
    accentColor: 0xFF93c5fd,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFFFFFFF,
    successColor: 0xFF3b82f6,
    errorColor: 0xFFef4444,
    warningColor: 0xFFfbbf24,
    timerColor: 0xFF3b82f6,
    downloadColor: 0xFF3b82f6,
    uploadColor: 0xFF60a5fa,
    borderColor: 0xFFFFFFFF,
    dividerColor: 0xFFFFFFFF,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.05,
    cardOpacity: 1.0,
  );

  // Dark Purple Theme - Vibrant & Energetic
  factory ThemeColors.sunsetTheme() => ThemeColors(
    backgroundColor: 0xFF0a0510,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFF1a1a1a,
    primaryColor: 0xFF8b5cf6,
    secondaryColor: 0xFFa78bfa,
    accentColor: 0xFFc4b5fd,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFFFFFFF,
    successColor: 0xFF8b5cf6,
    errorColor: 0xFFef4444,
    warningColor: 0xFFfbbf24,
    timerColor: 0xFF8b5cf6,
    downloadColor: 0xFF8b5cf6,
    uploadColor: 0xFFa78bfa,
    borderColor: 0xFFFFFFFF,
    dividerColor: 0xFFFFFFFF,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.05,
    cardOpacity: 1.0,
  );

  // Dark Red Theme - Bold & Powerful
  factory ThemeColors.forestTheme() => ThemeColors(
    backgroundColor: 0xFF050a05,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFF1a1a1a,
    primaryColor: 0xFFef4444,
    secondaryColor: 0xFFf87171,
    accentColor: 0xFFfca5a5,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFFFFFFF,
    successColor: 0xFFef4444,
    errorColor: 0xFFdc2626,
    warningColor: 0xFFfbbf24,
    timerColor: 0xFFef4444,
    downloadColor: 0xFFef4444,
    uploadColor: 0xFFf87171,
    borderColor: 0xFFFFFFFF,
    dividerColor: 0xFFFFFFFF,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.05,
    cardOpacity: 1.0,
  );
}
