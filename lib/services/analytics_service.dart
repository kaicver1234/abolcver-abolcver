import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  /// Log VPN connection event
  Future<void> logVpnConnect({
    required String serverName,
    required String country,
    String? protocol,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vpn_connect',
        parameters: {
          'server_name': serverName,
          'country': country,
          'protocol': protocol ?? 'unknown',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log VPN disconnection event
  Future<void> logVpnDisconnect({
    required String serverName,
    required int durationSeconds,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vpn_disconnect',
        parameters: {
          'server_name': serverName,
          'duration_seconds': durationSeconds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log subscription addition
  Future<void> logSubscriptionAdded({
    required String subscriptionName,
    required int serverCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_added',
        parameters: {
          'subscription_name': subscriptionName,
          'server_count': serverCount,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log subscription update
  Future<void> logSubscriptionUpdated({
    required String subscriptionName,
    required int newServerCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_updated',
        parameters: {
          'subscription_name': subscriptionName,
          'new_server_count': newServerCount,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log app update check
  Future<void> logUpdateCheck({
    required String currentVersion,
    required String latestVersion,
    required bool updateAvailable,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'update_check',
        parameters: {
          'current_version': currentVersion,
          'latest_version': latestVersion,
          'update_available': updateAvailable,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log language change
  Future<void> logLanguageChange({
    required String fromLanguage,
    required String toLanguage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'language_change',
        parameters: {
          'from_language': fromLanguage,
          'to_language': toLanguage,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Log connection error
  Future<void> logConnectionError({
    required String errorType,
    required String errorMessage,
    String? serverName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'connection_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          if (serverName != null) 'server_name': serverName,
        },
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Set user property (e.g., preferred language, app version)
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Set user ID (optional, for tracking specific users)
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      // Silently fail
    }
  }
}
