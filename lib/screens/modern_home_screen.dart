import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../models/app_language.dart';
import '../utils/app_localizations.dart';
import '../utils/country_flags.dart';
import '../utils/responsive_helper.dart';
import '../widgets/app_background.dart';
import '../widgets/modern_glass_card.dart';
import '../widgets/modern_connection_button.dart';
import '../widgets/modern_bottom_nav.dart';
import '../screens/server_selection_screen.dart';
import '../screens/ip_info_screen.dart';
import '../screens/speedtest_screen.dart';
import '../screens/host_checker_screen.dart';
import '../services/remote_config_service.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _isConnecting = false;
  late PageController _pageController;
  int _currentPage = 1; // Start from VPN tab (middle)
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncVpnStatus();
      _loadServers();
    });
  }
  
  Future<void> _syncVpnStatus() async {
    if (!mounted) return;
    final provider = Provider.of<V2RayProvider>(context, listen: false);
    await provider.forceSyncVpnStatus();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await provider.forceSyncVpnStatus();
      setState(() {});
    }
  }
  
  Future<void> _loadServers() async {
    if (!mounted) return;
    final provider = Provider.of<V2RayProvider>(context, listen: false);
    if (provider.serverConfigs.isEmpty) {
      await provider.fetchServers();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _syncVpnStatus();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleConnectionToggle() async {
    if (_isConnecting) return;

    if (!mounted) return;
    setState(() => _isConnecting = true);

    final provider = Provider.of<V2RayProvider>(context, listen: false);

    try {
      if (provider.activeConfig != null) {
        await provider.disconnect();
      } else {
        if (provider.wasUsingSmartConnect) {
          await provider.smartConnect();
        } else {
          if (provider.selectedConfig == null && provider.configs.isNotEmpty) {
            await provider.selectConfig(provider.configs.first);
          }
          
          if (provider.selectedConfig == null) {
            if (mounted) {
              _showSnackBar(
                AppLocalizations.of(context).translate('common.please_select_server'), 
                Colors.red
              );
            }
          } else {
            await provider.connectToServer(provider.selectedConfig!);
          }
        }
        
        if (mounted && provider.errorMessage.isNotEmpty) {
          _showSnackBar(provider.errorMessage, Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '${AppLocalizations.of(context).translate('common.connection_failed')}: $e', 
          Colors.red
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer2<V2RayProvider, LanguageProvider>(
      builder: (context, v2rayProvider, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: AppBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildModernHeader(context, languageProvider),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      children: [
                        _buildToolsPage(context),
                        _buildVPNPage(v2rayProvider),
                        _buildAboutPage(context),
                      ],
                    ),
                  ),
                  ModernBottomNav(
                    currentIndex: _currentPage,
                    onTap: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    items: [
                      ModernNavItem(
                        icon: Icons.apps_outlined,
                        activeIcon: Icons.apps,
                        label: AppLocalizations.of(context).translate('navigation.tools'),
                        color: const Color(0xFFFF6B9D),
                      ),
                      ModernNavItem(
                        icon: Icons.shield_outlined,
                        activeIcon: Icons.shield,
                        label: 'VPN',
                        color: const Color(0xFF00D9FF),
                      ),
                      ModernNavItem(
                        icon: Icons.info_outline,
                        activeIcon: Icons.info,
                        label: AppLocalizations.of(context).translate('navigation.about'),
                        color: const Color(0xFF00FFA3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(BuildContext context, LanguageProvider languageProvider) {
    final responsive = ResponsiveHelper(context);
    
    return Padding(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Info - Simple (No Logo)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TiksarVPN',
                style: GoogleFonts.poppins(
                  fontSize: responsive.headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Secure & Fast',
                style: GoogleFonts.poppins(
                  fontSize: responsive.headerFontSize * 0.55,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          
          // Language Button
          GestureDetector(
            onTap: () => _showLanguageModal(context),
            child: ModernGlassCard(
              padding: EdgeInsets.all(responsive.scale(12)),
              borderRadius: BorderRadius.circular(14),
              child: Icon(
                Icons.language,
                color: Colors.white,
                size: responsive.scale(22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languages = [
      {'name': 'فارسی', 'code': 'fa', 'flag': '🇮🇷'},
      {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernGlassCard(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        blur: 20,
        opacity: 0.15,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('language_settings.language'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...languages.map((lang) {
              final isSelected = languageProvider.currentLanguage.code == lang['code'];
              return GestureDetector(
                onTap: () async {
                  final newLanguage = AppLanguage(
                    name: lang['name']!,
                    code: lang['code']!,
                    flag: lang['flag']!,
                    direction: lang['code'] == 'fa' ? 'rtl' : 'ltr',
                  );
                  await languageProvider.changeLanguage(newLanguage);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          lang['name']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: lang['code'] == 'fa' ? 16 : 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }



  String _cleanServerName(String name) {
    return name.replaceAll(RegExp(r'^\[[A-Z]{2}\]\s*'), '').trim();
  }

  Widget _buildConnectionTimer(V2RayProvider provider) {
    final responsive = ResponsiveHelper(context);
    final isConnected = provider.activeConfig != null;
    
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Center(
          child: Text(
            isConnected 
                ? provider.v2rayService.getFormattedConnectedTime()
                : '00:00:00',
            style: GoogleFonts.orbitron(
              fontSize: responsive.timerFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
        );
      },
    );
  }



  // VPN Page - Main connection page
  Widget _buildVPNPage(V2RayProvider provider) {
    final responsive = ResponsiveHelper(context);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        child: Column(
          children: [
            SizedBox(height: responsive.responsiveValue(small: 50, medium: 55, large: 60)),
            
            // Connection Button with Status
            _buildConnectionButtonWithStatus(provider),
            
            SizedBox(height: responsive.responsiveValue(small: 32, medium: 36, large: 40)),
            
            // Server Card
            _buildServerCard(provider),
            
            SizedBox(height: responsive.verticalSpacing),
            
            // Connection Timer
            _buildConnectionTimer(provider),
            
            SizedBox(height: responsive.verticalSpacing),
            
            // Stats Grid
            _buildStatsGrid(provider),
            
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButtonWithStatus(V2RayProvider provider) {
    final responsive = ResponsiveHelper(context);
    final isConnected = provider.activeConfig != null;
    final isConnecting = _isConnecting;
    
    String statusText;
    if (isConnecting) {
      statusText = AppLocalizations.of(context).translate('common.connecting');
    } else if (isConnected) {
      statusText = AppLocalizations.of(context).translate('common.connected');
    } else {
      statusText = AppLocalizations.of(context).translate('common.disconnected');
    }
    
    return Column(
      children: [
        ModernConnectionButton(
          isConnected: isConnected,
          isConnecting: isConnecting,
          onTap: _handleConnectionToggle,
          size: responsive.connectionButtonSize,
        ),
        const SizedBox(height: 12),
        Text(
          statusText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildServerCard(V2RayProvider provider) {
    final responsive = ResponsiveHelper(context);
    final isSmartConnect = provider.wasUsingSmartConnect;
    final selectedConfig = provider.selectedConfig ?? provider.activeConfig;
    
    String serverName;
    String? countryCode;
    
    if (provider.activeConfig != null) {
      serverName = _cleanServerName(provider.activeConfig!.remark);
      countryCode = provider.activeConfig!.countryCode;
    } else if (isSmartConnect) {
      serverName = AppLocalizations.of(context).translate('server_selection.smart_connect');
    } else if (selectedConfig != null) {
      serverName = _cleanServerName(selectedConfig.remark);
      countryCode = selectedConfig.countryCode;
    } else {
      serverName = AppLocalizations.of(context).translate('server_selection.select_server');
    }
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ServerSelectionScreen()),
      ),
      child: Container(
        padding: EdgeInsets.all(responsive.serverCardPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Left accent line
            Positioned(
              left: -responsive.serverCardPadding,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Row(
              children: [
                // Flag/Icon with gradient and highlight
                Stack(
                  children: [
                    Container(
                      width: responsive.serverIconSize,
                      height: responsive.serverIconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildServerIconContent(countryCode, isSmartConnect && provider.activeConfig == null),
                      ),
                    ),
                    // Top highlight
                    Positioned(
                      top: 6,
                      left: 6,
                      right: 6,
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Server info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('server_selection.current_server').toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: responsive.scale(10),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serverName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.scale(15),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Arrow button
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, _) => Container(
                    width: responsive.scale(34),
                    height: responsive.scale(34),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      langProvider.isRtl ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: responsive.scale(18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerIconContent(String? countryCode, bool isSmartConnect) {
    if (countryCode != null && CountryFlags.isValidCountryCode(countryCode)) {
      return CachedNetworkImage(
        imageUrl: CountryFlags.getFlagUrl(countryCode),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.white.withValues(alpha: 0.1),
          child: const Icon(Icons.public, color: Colors.white, size: 24),
        ),
      );
    }
    
    return Icon(
      isSmartConnect ? Icons.flash_on : Icons.language,
      color: Colors.white,
      size: 24,
    );
  }

  Widget _buildStatsGrid(V2RayProvider provider) {
    final v2rayService = provider.v2rayService;
    final isConnected = provider.activeConfig != null;
    
    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 500)),
      builder: (context, snapshot) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.arrow_downward_rounded,
                label: AppLocalizations.of(context).translate('home.download'),
                value: isConnected ? v2rayService.getFormattedDownload() : '0 B',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.arrow_upward_rounded,
                label: AppLocalizations.of(context).translate('home.upload'),
                value: isConnected ? v2rayService.getFormattedUpload() : '0 B',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final responsive = ResponsiveHelper(context);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.5),
              size: responsive.statsIconSize,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: responsive.statsLabelFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: responsive.statsValueFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Tools Page - Quick access to tools
  Widget _buildToolsPage(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final tools = [
      {
        'icon': Icons.speed_rounded,
        'label': AppLocalizations.of(context).translate('home.speed_test'),
        'subtitle': AppLocalizations.of(context).translate('tools.speed_test_desc'),
        'color': const Color(0xFF00D9FF),
        'screen': const SpeedTestScreen(),
      },
      {
        'icon': Icons.info_outline_rounded,
        'label': AppLocalizations.of(context).translate('home.ip_info'),
        'subtitle': AppLocalizations.of(context).translate('tools.ip_information_desc'),
        'color': const Color(0xFF00FFA3),
        'screen': const IpInfoScreen(),
      },
      {
        'icon': Icons.dns_rounded,
        'label': AppLocalizations.of(context).translate('home.host_checker'),
        'subtitle': AppLocalizations.of(context).translate('tools.host_checker_desc'),
        'color': const Color(0xFFFF6B9D),
        'screen': const HostCheckerScreen(),
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Simple Title Only
          Text(
            AppLocalizations.of(context).translate('navigation.tools'),
            style: GoogleFonts.poppins(
              fontSize: responsive.pageTitleFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: responsive.verticalSpacing),
          
          // Tools Grid
          ...tools.map((tool) => Padding(
            padding: EdgeInsets.only(bottom: responsive.scale(16)),
            child: _buildToolCard(
              icon: tool['icon'] as IconData,
              label: tool['label'] as String,
              subtitle: tool['subtitle'] as String,
              color: tool['color'] as Color,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => tool['screen'] as Widget),
              ),
            ),
          )),
          
          const SizedBox(height: 80), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ModernGlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Consumer<LanguageProvider>(
              builder: (context, langProvider, _) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  langProvider.isRtl ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // About Page - Clean and Modern Design
  Widget _buildAboutPage(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final description = remoteConfig.getAboutDescription(languageProvider.currentLanguage.code);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Logo - Simple & Clean
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/apk.png', fit: BoxFit.cover),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App Name & Version
          Text(
            'TiksarVPN',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 6),
          
          Text(
            'Version 1.1.4',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Description - Simple Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Divider Line
          Container(
            width: 60,
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          
          const SizedBox(height: 40),
          
          // Developer - Simple
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).translate('about.developed_with'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('about.developer'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Social Links - Clean Design
          _buildCleanSocialLink(
            icon: Icons.send_rounded,
            name: AppLocalizations.of(context).translate('about.telegram'),
            title: remoteConfig.telegramId,
            url: remoteConfig.telegramUrl,
          ),
          const SizedBox(height: 10),
          _buildCleanSocialLink(
            icon: Icons.camera_alt_rounded,
            name: AppLocalizations.of(context).translate('about.instagram'),
            title: remoteConfig.instagramId,
            url: remoteConfig.instagramUrl,
          ),
          const SizedBox(height: 10),
          _buildCleanSocialLink(
            icon: Icons.location_city_rounded,
            name: AppLocalizations.of(context).translate('about.tiksar_village_page'),
            title: remoteConfig.tiksarPageId,
            url: remoteConfig.tiksarPageUrl,
          ),
          
          const SizedBox(height: 50),
          
          // Copyright - Simple
          const Text(
            '© 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 0.25),
              fontSize: 11,
            ),
          ),
          
          const SizedBox(height: 100), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildCleanSocialLink({
    required IconData icon,
    required String name,
    required String title,
    required String url,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Consumer<LanguageProvider>(
              builder: (context, langProvider, _) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  langProvider.isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Beating heart widget - REMOVED (not needed anymore)

