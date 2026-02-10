import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../models/app_theme_model.dart';
import '../utils/app_localizations.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Directionality(
      textDirection: languageProvider.textDirection,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final colors = themeProvider.colors;
          
          return Scaffold(
            backgroundColor: Color(colors.backgroundColor),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, colors),
                  Expanded(
                    child: _buildThemeList(context, themeProvider, colors),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeColors colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        8,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(colors.borderColor).withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: isSmallScreen ? 40 : 44,
              height: isSmallScreen ? 40 : 44,
              decoration: BoxDecoration(
                color: Color(colors.surfaceColor).withValues(alpha: colors.surfaceOpacity),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Color(colors.textPrimaryColor),
                size: isSmallScreen ? 16 : 18,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('theme.title'),
                  style: TextStyle(
                    color: Color(colors.textPrimaryColor),
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).translate('theme.subtitle'),
                  style: TextStyle(
                    color: Color(colors.textSecondaryColor).withValues(alpha: 0.5),
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeList(BuildContext context, ThemeProvider themeProvider, ThemeColors colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      physics: const BouncingScrollPhysics(),
      itemCount: themeProvider.availableThemes.length,
      itemBuilder: (context, index) {
        final theme = themeProvider.availableThemes[index];
        final isSelected = themeProvider.currentTheme.id == theme.id;
        final themeName = languageProvider.currentLanguage.code == 'fa' 
            ? theme.nameFa 
            : theme.nameEn;
        
        return _buildThemeCard(
          context,
          theme,
          themeName,
          isSelected,
          colors,
          isSmallScreen,
          () => themeProvider.changeTheme(theme),
        );
      },
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppThemeModel theme,
    String themeName,
    bool isSelected,
    ThemeColors currentColors,
    bool isSmallScreen,
    VoidCallback onTap,
  ) {
    final themeColors = theme.colors;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: Color(currentColors.surfaceColor).withValues(alpha: currentColors.surfaceOpacity),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Color(currentColors.primaryColor).withValues(alpha: 0.5)
                : Color(currentColors.borderColor).withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          child: Row(
            children: [
              // Theme preview
              _buildThemePreview(themeColors, isSmallScreen),
              SizedBox(width: isSmallScreen ? 14 : 16),
              // Theme info
              Expanded(
                child: Text(
                  themeName,
                  style: TextStyle(
                    color: Color(currentColors.textPrimaryColor),
                    fontSize: isSmallScreen ? 15 : 17,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Selection indicator
              Container(
                width: isSmallScreen ? 22 : 24,
                height: isSmallScreen ? 22 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? Color(currentColors.primaryColor) 
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? Color(currentColors.primaryColor)
                        : Color(currentColors.borderColor).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: isSmallScreen ? 14 : 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemePreview(ThemeColors colors, bool isSmallScreen) {
    final size = isSmallScreen ? 50.0 : 55.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(colors.primaryColor),
            Color(colors.secondaryColor),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(colors.primaryColor).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
