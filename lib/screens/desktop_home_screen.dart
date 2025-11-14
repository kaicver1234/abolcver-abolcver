import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/desktop_layout.dart';
import '../utils/app_localizations.dart';
import '../utils/platform_utils.dart';
import '../screens/server_selection_screen.dart';
import '../screens/ip_info_screen.dart';
import '../screens/speedtest_screen.dart';
import '../screens/host_checker_screen.dart';
import '../screens/about_screen.dart';

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({Key? key}) : super(key: key);

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _isConnecting = false;
  int _selectedNavIndex = 0;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer2<V2RayProvider, LanguageProvider>(
      builder: (context, v2rayProvider, languageProvider, child) {
        final localizations = AppLocalizations.of(context);
        
        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          body: Row(
            children: [
              _buildSidebar(context, localizations),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, localizations),
                      const SizedBox(height: 32),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildMainPanel(context, v2rayProvider, localizations),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildStatsPanel(context, v2rayProvider, localizations),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1F2E),
            const Color(0xFF0F131E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.vpn_lock_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiksar VPN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'v1.1.1',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF1E2433), thickness: 1),
          const SizedBox(height: 20),
          
          _buildNavItem(Icons.home_rounded, localizations.translate('nav.home'), 0),
          _buildNavItem(Icons.speed_rounded, localizations.translate('nav.speedTest'), 1),
          _buildNavItem(Icons.info_outline_rounded, localizations.translate('nav.ipInfo'), 2),
          _buildNavItem(Icons.dns_rounded, localizations.translate('nav.hostChecker'), 3),
          _buildNavItem(Icons.language_rounded, localizations.translate('nav.servers'), 4),
          
          const Spacer(),
          
          const Divider(color: Color(0xFF1E2433), thickness: 1),
          
          _buildNavItem(Icons.settings_rounded, localizations.translate('nav.settings'), 5),
          _buildNavItem(Icons.info_rounded, localizations.translate('nav.about'), 6),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedNavIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavItemTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
  
  void _onNavItemTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpeedTestScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IpInfoScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HostCheckerScreen()),
        );
        break;
      case 4:
        _navigateToServerSelection(context);
        break;
      case 5:
        break;
      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
        break;
    }
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('home.welcome'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('home.subtitle'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.computer_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Windows',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainPanel(BuildContext context, V2RayProvider v2rayProvider, AppLocalizations localizations) {
    final isConnected = v2rayProvider.v2rayService.isConnected;
    final status = _isConnecting 
        ? localizations.translate('home.connecting')
        : (isConnected ? localizations.translate('home.connected') : localizations.translate('home.disconnected'));
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isConnected 
            ? [const Color(0xFF1A3A2E), const Color(0xFF0F2922)]
            : [const Color(0xFF1A1F2E), const Color(0xFF0F131E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isConnected 
            ? const Color(0xFF00FF87).withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected 
              ? const Color(0xFF00FF87).withOpacity(0.2)
              : Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          _buildStatusIndicator(isConnected, status),
          
          const SizedBox(height: 40),
          
          _buildConnectionButton(context, v2rayProvider, localizations, isConnected),
          
          const SizedBox(height: 32),
          
          _buildServerCard(context, v2rayProvider, localizations),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isConnected, String status) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isConnected 
                    ? [
                        const Color(0xFF00FF87).withOpacity(0.3),
                        const Color(0xFF00FF87).withOpacity(0.0),
                      ]
                    : [
                        const Color(0xFF667EEA).withOpacity(0.3),
                        const Color(0xFF667EEA).withOpacity(0.0),
                      ],
                ),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            ).scale(
              duration: 2.seconds,
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.05, 1.05),
            ),
            
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isConnected 
                    ? [const Color(0xFF00FF87), const Color(0xFF60EFFF)]
                    : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isConnected 
                      ? const Color(0xFF00FF87).withOpacity(0.5)
                      : const Color(0xFF667EEA).withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                isConnected ? Icons.verified_user_rounded : Icons.shield_outlined,
                color: Colors.white,
                size: 64,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          ],
        ),
        
        const SizedBox(height: 32),
        
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isConnected 
              ? [const Color(0xFF00FF87), const Color(0xFF60EFFF)]
              : [const Color(0xFF667EEA), const Color(0xFFB06AB3)],
          ).createShader(bounds),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          isConnected 
            ? 'Your connection is secure and encrypted'
            : 'Connect to secure your connection',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionButton(BuildContext context, V2RayProvider v2rayProvider, AppLocalizations localizations, bool isConnected) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: _isConnecting ? null : () => _handleConnection(v2rayProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isConnected 
                ? [const Color(0xFFE72E44), const Color(0xFFB91C1C)]
                : [const Color(0xFF00FF87), const Color(0xFF60EFFF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isConnected 
                  ? const Color(0xFFE72E44).withOpacity(0.4)
                  : const Color(0xFF00FF87).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isConnecting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      localizations.translate('home.connecting'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isConnected ? Icons.power_off_rounded : Icons.power_settings_new_rounded,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isConnected ? localizations.translate('home.disconnect') : localizations.translate('home.connect'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    ).animate().scale(duration: 200.ms);
  }

  Widget _buildServerCard(BuildContext context, V2RayProvider v2rayProvider, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dns_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('home.currentServer'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  v2rayProvider.selectedConfig?.remark ?? localizations.translate('home.noServerSelected'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _navigateToServerSelection(context),
            icon: const Icon(Icons.chevron_right_rounded),
            color: Colors.white.withOpacity(0.8),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(BuildContext context, V2RayProvider v2rayProvider, AppLocalizations localizations) {
    return Column(
      children: [
        _buildStatCard(
          'Connection Stats',
          Icons.analytics_rounded,
          [
            _buildStatRow(
              Icons.upload_rounded,
              localizations.translate('home.upload'),
              _formatSpeed(v2rayProvider.currentStatus?.uploadSpeed ?? 0),
              const Color(0xFF72D9FF),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              Icons.download_rounded,
              localizations.translate('home.download'),
              _formatSpeed(v2rayProvider.currentStatus?.downloadSpeed ?? 0),
              const Color(0xFF76F959),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              Icons.timer_rounded,
              localizations.translate('home.duration'),
              v2rayProvider.currentStatus?.duration ?? '00:00:00',
              const Color(0xFFFFAA66),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        _buildStatCard(
          'System Information',
          Icons.computer_rounded,
          [
            _buildInfoRow('Platform', 'Windows 10/11'),
            const SizedBox(height: 12),
            _buildInfoRow('Core Version', 'V2Ray 5.10.0'),
            const SizedBox(height: 12),
            _buildInfoRow('App Version', '1.1.1'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F2E), Color(0xFF0F131E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _handleConnection(V2RayProvider v2rayProvider) async {
    if (v2rayProvider.v2rayService.isConnected) {
      setState(() => _isConnecting = true);
      await v2rayProvider.disconnect();
      setState(() => _isConnecting = false);
    } else {
      if (v2rayProvider.selectedConfig == null) {
        _navigateToServerSelection(context);
        return;
      }
      
      setState(() => _isConnecting = true);
      await v2rayProvider.connectToServer(v2rayProvider.selectedConfig!);
      setState(() => _isConnecting = false);
    }
  }
  
  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(2)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }

  void _navigateToServerSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServerSelectionScreen()),
    );
  }
}
