import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;
  bool _isSupported = false;

  FirebaseAnalytics? get analytics => _analytics;

  /// Check if analytics is supported on this platform
  bool get isSupported => _isSupported;

  /// Initialize Analytics with app info
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Skip analytics on desktop platforms
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      debugPrint('💻 Analytics: Skipped on desktop platform');
      _isSupported = false;
      _isInitialized = true;
      return;
    }
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _isSupported = true;
      
      await _analytics!.setAnalyticsCollectionEnabled(true);
      
      // Set app version as user property
      final packageInfo = await PackageInfo.fromPlatform();
      await setUserProperty(
        name: 'app_version',
        value: packageInfo.version,
      );
      await setUserProperty(
        name: 'build_number',
        value: packageInfo.buildNumber,
      );
      
      _isInitialized = true;
      debugPrint('✅ Analytics initialized successfully');
    } catch (e) {
      debugPrint('❌ Analytics initialization failed: $e');
      _isSupported = false;
    }
  }

  // ── Central event helper ───────────────────────────────────────────────
  //
  // Every public log* method funnels through here so the support guard,
  // error handling and Firebase's value-type/length constraints live in ONE
  // place instead of being copy-pasted (and drifting) across ~25 methods.
  //
  // Firebase Analytics constraints enforced here:
  //   • Parameter values must be String or num — bool is silently dropped, so
  //     we coerce bool → int (1/0) via [_sanitizeParams].
  //   • String values are capped at 100 chars; longer values cause the whole
  //     event to be rejected, so we truncate.
  //   • A manual `timestamp` param is redundant (Firebase stamps every event)
  //     and wastes one of the 25 allowed params — callers no longer pass it.
  Future<void> _log(
    String name, {
    Map<String, Object?>? params,
    String? debugLabel,
  }) async {
    if (!_isSupported || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: params == null ? null : _sanitizeParams(params),
      );
      if (debugLabel != null) {
        debugPrint('📊 Analytics: $debugLabel');
      }
    } catch (e) {
      debugPrint('⚠️ Analytics error [$name]: $e');
    }
  }

  /// Coerce a loosely-typed param map into what Firebase accepts: keys map to
  /// String or num only. Bools become 1/0, null entries are dropped, and
  /// over-long strings are truncated to the 100-char limit.
  Map<String, Object> _sanitizeParams(Map<String, Object?> params) {
    final out = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        out[key] = value ? 1 : 0;
      } else if (value is num) {
        out[key] = value;
      } else {
        final s = value.toString();
        out[key] = s.length > 100 ? s.substring(0, 100) : s;
      }
    });
    return out;
  }

  /// Log VPN connection event
  Future<void> logVpnConnect({
    required String serverName,
    required String serverAddress,
    required int serverPort,
    String? country,
    String? protocol,
  }) {
    return _log(
      'vpn_connect',
      params: {
        'server_name': serverName,
        'server_address': serverAddress,
        'server_port': serverPort,
        'country': country ?? 'unknown',
        'protocol': protocol ?? 'vmess',
        'connection_method': 'manual',
      },
      debugLabel: 'VPN Connect - $serverName',
    );
  }

  /// Log auto-connect event
  Future<void> logAutoConnect({
    required String serverName,
  }) {
    return _log(
      'vpn_auto_connect',
      params: {'server_name': serverName},
      debugLabel: 'Auto Connect - $serverName',
    );
  }

  /// Log VPN disconnection event
  Future<void> logVpnDisconnect({
    required String serverName,
    required int durationSeconds,
    required int uploadBytes,
    required int downloadBytes,
    String? disconnectReason,
  }) {
    return _log(
      'vpn_disconnect',
      params: {
        'server_name': serverName,
        'duration_seconds': durationSeconds,
        'upload_bytes': uploadBytes,
        'download_bytes': downloadBytes,
        'total_bytes': uploadBytes + downloadBytes,
        'disconnect_reason': disconnectReason ?? 'user_action',
      },
      debugLabel:
          'VPN Disconnect - Duration: ${durationSeconds}s, Data: ${(uploadBytes + downloadBytes) / 1024 / 1024}MB',
    );
  }

  /// Log connection failure
  Future<void> logConnectionFailure({
    required String serverName,
    required String errorMessage,
  }) {
    return _log(
      'vpn_connection_failure',
      params: {
        'server_name': serverName,
        'error_message': errorMessage,
      },
      debugLabel: 'Connection Failure - $serverName',
    );
  }

  /// Log subscription addition
  Future<void> logSubscriptionAdded({
    required String subscriptionName,
    required int serverCount,
    required String subscriptionType,
  }) {
    return _log(
      'subscription_added',
      params: {
        'subscription_name': subscriptionName,
        'server_count': serverCount,
        'subscription_type': subscriptionType,
      },
      debugLabel: 'Subscription Added - $serverCount servers',
    );
  }

  /// Log subscription update
  Future<void> logSubscriptionUpdated({
    required String subscriptionName,
    required int newServerCount,
  }) {
    return _log(
      'subscription_updated',
      params: {
        'subscription_name': subscriptionName,
        'new_server_count': newServerCount,
      },
    );
  }

  /// Log app update check
  Future<void> logUpdateCheck({
    required String currentVersion,
    required String latestVersion,
    required bool updateAvailable,
  }) {
    return _log(
      'update_check',
      params: {
        'current_version': currentVersion,
        'latest_version': latestVersion,
        'update_available': updateAvailable,
      },
    );
  }

  /// Log language change
  Future<void> logLanguageChange({
    required String fromLanguage,
    required String toLanguage,
  }) {
    return _log(
      'language_change',
      params: {
        'from_language': fromLanguage,
        'to_language': toLanguage,
      },
    );
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isSupported || _analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('⚠️ Analytics error [screen_view]: $e');
    }
  }

  /// Log connection error
  Future<void> logConnectionError({
    required String errorType,
    required String errorMessage,
    String? serverName,
  }) {
    return _log(
      'connection_error',
      params: {
        'error_type': errorType,
        'error_message': errorMessage,
        'server_name': serverName,
      },
      debugLabel: 'Connection Error - $errorType',
    );
  }

  /// Log server ping test
  Future<void> logServerPing({
    required String serverName,
    required int pingMs,
    required bool success,
  }) {
    return _log(
      'server_ping_test',
      params: {
        'server_name': serverName,
        'ping_ms': pingMs,
        'success': success,
      },
    );
  }

  /// Log server selection
  Future<void> logServerSelection({
    required String serverName,
    required String selectionMethod,
  }) {
    return _log(
      'server_selection',
      params: {
        'server_name': serverName,
        'selection_method': selectionMethod, // 'manual', 'auto', 'fastest'
      },
      debugLabel: 'Server Selected - $serverName ($selectionMethod)',
    );
  }

  /// Log app feature usage
  Future<void> logFeatureUsage({
    required String featureName,
    Map<String, dynamic>? additionalParams,
  }) {
    return _log(
      'feature_usage',
      params: {
        'feature_name': featureName,
        if (additionalParams != null) ...additionalParams,
      },
      debugLabel: 'Feature Used - $featureName',
    );
  }

  /// Log user session
  Future<void> logAppOpen() async {
    if (!_isSupported || _analytics == null) return;

    try {
      await _analytics!.logAppOpen();
      debugPrint('📊 Analytics: App Opened');
    } catch (e) {
      debugPrint('⚠️ Analytics error [app_open]: $e');
    }
  }

  /// Log settings change
  Future<void> logSettingsChange({
    required String settingName,
    required String newValue,
  }) {
    return _log(
      'settings_change',
      params: {
        'setting_name': settingName,
        'new_value': newValue,
      },
      debugLabel: 'Setting Changed - $settingName: $newValue',
    );
  }

  /// Set user property (e.g., preferred language, app version)
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isSupported || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Set user ID (optional, for tracking specific users)
  Future<void> setUserId(String userId) async {
    if (!_isSupported || _analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Log tab change in home screen
  Future<void> logTabChange({
    required String tabName,
    required int tabIndex,
  }) {
    return _log(
      'tab_taghir',
      params: {
        'tab_name': tabName,
        'tab_index': tabIndex,
      },
      debugLabel: 'Tab Taghir - $tabName',
    );
  }

  /// Log DNS settings change
  Future<void> logDnsChange({
    required String dnsType,
    required String dnsValue,
  }) {
    return _log(
      'tanzimate_dns_taghir',
      params: {
        'dns_type': dnsType,
        'dns_value': dnsValue,
      },
      debugLabel: 'DNS Taghir - $dnsType: $dnsValue',
    );
  }

  /// Log speed test start
  Future<void> logSpeedTestStart() {
    return _log('test_saraat_shoru', debugLabel: 'Test Saraat Shoru');
  }

  /// Log speed test result
  Future<void> logSpeedTestResult({
    required double downloadMbps,
    required double uploadMbps,
    required int pingMs,
  }) {
    return _log(
      'natije_test_saraat',
      params: {
        'download_mbps': downloadMbps.toStringAsFixed(1),
        'upload_mbps': uploadMbps.toStringAsFixed(1),
        'ping_ms': pingMs,
      },
      debugLabel:
          'Natije Test Saraat - D:${downloadMbps.toStringAsFixed(1)} U:${uploadMbps.toStringAsFixed(1)}',
    );
  }

  /// Log host check
  Future<void> logHostCheck({
    required String host,
    required bool isReachable,
    required int responseTimeMs,
  }) {
    return _log(
      'baresi_host',
      params: {
        'host': host,
        'ghabele_dastresi': isReachable,
        'zaman_pasokh_ms': responseTimeMs,
      },
      debugLabel:
          'Baresi Host - $host (${isReachable ? "movafagh" : "nabood"})',
    );
  }

  /// Log server list refresh
  Future<void> logServerListRefresh({
    required int serverCount,
  }) {
    return _log(
      'berozresani_list_server',
      params: {'tedad_server': serverCount},
      debugLabel: 'Berozresani List Server - $serverCount ta',
    );
  }

  /// Log smart connect usage
  Future<void> logSmartConnect({
    required String selectedServer,
  }) {
    return _log(
      'otaghak_hoshmandam',
      params: {'server_entekhabi': selectedServer},
      debugLabel: 'Otaghak Hoshmandam - $selectedServer',
    );
  }

  /// Log IP info screen refresh
  Future<void> logIpInfoRefresh() {
    return _log('berozresani_ettelaat_ip');
  }

  /// Log about screen social link tap
  Future<void> logSocialLinkTap({
    required String platform,
  }) {
    return _log(
      'link_ejtemai_zade_shod',
      params: {'platform': platform},
      debugLabel: 'Link Ejtemai - $platform',
    );
  }
}
