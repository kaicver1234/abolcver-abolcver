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
      case 'light':
        return ThemeColors.lightTheme();
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

  // Dark Green Theme - Fresh & Modern
  factory ThemeColors.defaultTheme() => ThemeColors(
    backgroundColor: 0xFF0a0e14,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFFFFFFFF,
    primaryColor: 0xFF10b981,
    secondaryColor: 0xFFa78bfa,
    accentColor: 0xFF34d399,
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
    cardOpacity: 0.08,
  );

  // Light Theme - Soft & Eye-Friendly
  factory ThemeColors.lightTheme() => ThemeColors(
    backgroundColor: 0xFFf5f5f5, // Soft gray (warm and comfortable)
    surfaceColor: 0xFF1e293b,
    cardColor: 0xFFfefefe, // Off-white
    primaryColor: 0xFF059669, // Emerald green
    secondaryColor: 0xFF7c3aed, // Deep purple
    accentColor: 0xFF10b981, // Light emerald
    textPrimaryColor: 0xFF1f2937, // Dark gray (not black)
    textSecondaryColor: 0xFF6b7280, // Medium gray
    successColor: 0xFF059669,
    errorColor: 0xFFdc2626,
    warningColor: 0xFFea580c,
    timerColor: 0xFF059669,
    downloadColor: 0xFF059669,
    uploadColor: 0xFF10b981,
    borderColor: 0xFFd1d5db,
    dividerColor: 0xFFe5e7eb,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.04,
    cardOpacity: 1.0,
  );

  // Dark Blue Theme - Professional & Calm
  factory ThemeColors.oceanTheme() => ThemeColors(
    backgroundColor: 0xFF0a1628,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFFFFFFFF,
    primaryColor: 0xFF0ea5e9,
    secondaryColor: 0xFF6366f1,
    accentColor: 0xFF06b6d4,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFFFFFFF,
    successColor: 0xFF0ea5e9,
    errorColor: 0xFFef4444,
    warningColor: 0xFFfbbf24,
    timerColor: 0xFF0ea5e9,
    downloadColor: 0xFF0ea5e9,
    uploadColor: 0xFF06b6d4,
    borderColor: 0xFFFFFFFF,
    dividerColor: 0xFFFFFFFF,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.05,
    cardOpacity: 0.08,
  );

  // Dark Purple Theme - Vibrant & Energetic
  factory ThemeColors.sunsetTheme() => ThemeColors(
    backgroundColor: 0xFF1a0a1e,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFFFFFFFF,
    primaryColor: 0xFFa855f7,
    secondaryColor: 0xFFec4899,
    accentColor: 0xFFf472b6,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFFFFFFF,
    successColor: 0xFFa855f7,
    errorColor: 0xFFef4444,
    warningColor: 0xFFfbbf24,
    timerColor: 0xFFa855f7,
    downloadColor: 0xFFa855f7,
    uploadColor: 0xFFec4899,
    borderColor: 0xFFFFFFFF,
    dividerColor: 0xFFFFFFFF,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.05,
    cardOpacity: 0.08,
  );

  // Dark Red Theme - Bold & Powerful
  factory ThemeColors.forestTheme() => ThemeColors(
    backgroundColor: 0xFF1a0a0a,
    surfaceColor: 0xFFFFFFFF,
    cardColor: 0xFFFFFFFF,
    primaryColor: 0xFFff3b3b,
    secondaryColor: 0xFFff6b35,
    accentColor: 0xFFfbbf24,
    textPrimaryColor: 0xFFFFFFFF,
    textSecondaryColor: 0xFFFFFFFF,
    successColor: 0xFFff3b3b,
    errorColor: 0xFFdc2626,
    warningColor: 0xFFfbbf24,
    timerColor: 0xFFff3b3b,
    downloadColor: 0xFFff3b3b,
    uploadColor: 0xFFff6b35,
    borderColor: 0xFFFFFFFF,
    dividerColor: 0xFFFFFFFF,
    backgroundOpacity: 1.0,
    surfaceOpacity: 0.05,
    cardOpacity: 0.08,
  );
}
