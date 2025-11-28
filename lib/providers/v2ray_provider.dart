import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2ray_config.dart';
import '../models/subscription.dart';
import '../services/v2ray_service.dart';
import '../services/server_service.dart';
import '../services/analytics_service.dart';

class V2RayProvider with ChangeNotifier, WidgetsBindingObserver {
  final V2RayService _v2rayService = V2RayService();
  final ServerService _serverService = ServerService();
  final AnalyticsService _analyticsService = AnalyticsService();
  bool statusPingOnly = false;
  List<V2RayConfig> _configs = [];
  V2RayConfig? _selectedConfig;
  final List<Subscription> _subscriptions = [];
  
  // Subscriptions removed - using GitHub servers only
  bool _isConnecting = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoadingServers = false;
  bool _isInitializing = true;
  DateTime? _lastSuccessfulConnection;
  bool _wasUsingSmartConnect = false;
  DateTime? _lastStatusCheck;
  
  // Debounce for notifyListeners (battery optimized)
  Timer? _notifyDebounceTimer;
  DateTime? _lastNotifyTime;
  static const _minNotifyInterval = Duration(milliseconds: 200);
  
  // Method channel for VPN control
  static const platform = MethodChannel('com.tiksarvpn.app/vpn_control');
  
  // Event channel for receiving VPN status updates from native side
  static const EventChannel _vpnStatusEventChannel = EventChannel('com.tiksarvpn.app/vpn_status_events');
  StreamSubscription? _vpnStatusSubscription;

  // Return configs with Smart Connect at the top
  List<V2RayConfig> get configs {
    final smartConnect = V2RayConfig.smartConnect();
    return [smartConnect, ..._configs];
  }
  
  // Get actual server configs (without Smart Connect)
  List<V2RayConfig> get serverConfigs => _configs;
  V2RayConfig? get selectedConfig => _selectedConfig;
  V2RayConfig? get activeConfig => _v2rayService.activeConfig;
  bool get isConnecting => _isConnecting;
  bool get isLoading => _isLoading;
  bool get isLoadingServers => _isLoadingServers;
  String get errorMessage => _errorMessage;
  V2RayService get v2rayService => _v2rayService;
  bool get isInitializing => _isInitializing;
  bool get wasUsingSmartConnect => _wasUsingSmartConnect;

  // Expose V2Ray status for real-time traffic monitoring
  V2RayStatus? get currentStatus => _v2rayService.currentStatus;

  V2RayProvider() {
    WidgetsBinding.instance.addObserver(this);
    _v2rayService.addListener(_onV2RayServiceChanged);
    _setupVpnStatusListener();
    _initialize();
    platform.setMethodCallHandler(_handleMethodCall);
    _startPersistentConnectionMonitoring();
  }

  
  // Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'disconnectFromNotification':
        await _handleNotificationDisconnect();
        break;
      default:
        throw MissingPluginException();
    }
  }
  
  void _onV2RayServiceChanged() {
    // When V2RayService state changes, notify our listeners with debounce
    _debouncedNotify();
  }
  
  /// Debounced notify to prevent UI freeze from too many updates
  void _debouncedNotify() {
    final now = DateTime.now();
    if (_lastNotifyTime != null && 
        now.difference(_lastNotifyTime!) < _minNotifyInterval) {
      // Schedule a delayed notify if we're calling too fast
      _notifyDebounceTimer?.cancel();
      _notifyDebounceTimer = Timer(_minNotifyInterval, () {
        _lastNotifyTime = DateTime.now();
        notifyListeners();
      });
      return;
    }
    _lastNotifyTime = now;
    notifyListeners();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - checking VPN connection status...');
      
      // CRITICAL: When app comes back from background, immediately check VPN status
      // This ensures UI shows correct connection state even if app was killed/restarted
      Future.delayed(const Duration(milliseconds: 300), () async {
        try {
          debugPrint('🔄 Starting VPN status check after app resume...');
          
          // Force check actual VPN connection status
          await forceCheckVpnStatus();
          
          debugPrint('✅ VPN status check completed after app resume');
        } catch (e) {
          debugPrint('❌ Error checking VPN status after resume: $e');
          // Still notify to show last known state
          notifyListeners();
        }
      });
    } else if (state == AppLifecycleState.paused) {
      debugPrint('📱 App paused');
    }
  }
  
  /// سیستم مانیتورینگ هوشمند - بدون مصرف باتری
  /// فقط روی event-driven و lifecycle تکیه می‌کنه
  void _startPersistentConnectionMonitoring() {
    debugPrint('🔄 Starting smart connection monitoring (event-driven)...');
    
    // به جای تایمر دوره‌ای، فقط در مواقع خاص چک می‌کنیم:
    // 1. وقتی برنامه resume می‌شه (در didChangeAppLifecycleState)
    // 2. وقتی native event می‌فرسته (در _setupVpnStatusListener)
    // 3. وقتی کاربر دستی چک می‌کنه (در forceCheckVpnStatus)
    
    // این رویکرد:
    // ✅ صفر مصرف باتری در background
    // ✅ بلافاصله وقتی برنامه باز می‌شه چک می‌کنه
    // ✅ از native events برای تغییرات real-time استفاده می‌کنه
    
    debugPrint('✅ Smart monitoring active (zero battery drain)');
  }
  
  /// Setup VPN status event listener (inspired by defyxVPN)
  /// This listens to real-time VPN status changes from native side
  void _setupVpnStatusListener() {
    try {
      debugPrint('?? Setting up VPN status event listener...');
      
      _vpnStatusSubscription = _vpnStatusEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final Map<String, dynamic> statusEvent = Map<String, dynamic>.from(event);
            
            if (statusEvent.containsKey('status')) {
              final String vpnStatus = statusEvent['status'] as String;
              debugPrint('?? VPN status event received: $vpnStatus');
              
              // Handle VPN status changes from native side
              _handleNativeVpnStatusChange(vpnStatus);
            }
          }
        },
        onError: (dynamic error) {
          debugPrint('? Error from VPN status event channel: $error');
        },
      );
      
      debugPrint('? VPN status listener setup complete');
    } catch (e) {
      debugPrint('?? Could not setup VPN status listener: $e');
      // Continue without event listener - not critical
    }
  }
  
  /// Handle VPN status changes from native side
  void _handleNativeVpnStatusChange(String status) {
    debugPrint('?? Handling native VPN status change: $status');
    
    // CRITICAL FIX: Ignore ALL native events for 8 seconds after successful connection
    // This prevents race conditions where native sends stale events that reset UI
    // Using milliseconds to catch events that arrive within first second
    if (_lastSuccessfulConnection != null) {
      final timeSinceConnection = DateTime.now().difference(_lastSuccessfulConnection!);
      if (timeSinceConnection.inMilliseconds < 8000) {
        debugPrint('?? Ignoring ALL native events (within 8s grace period after connection)');
        debugPrint('?? Time since connection: ${timeSinceConnection.inMilliseconds}ms');
        return;
      }
    }
    
    switch (status.toLowerCase()) {
      case 'connected':
        // VPN connected from native side
        debugPrint('? Native reports VPN connected');
        
        // If we're already in connection process, skip sync to avoid UI reset
        if (_isConnecting) {
          debugPrint('?? Skipping sync - already in connection process');
          break;
        }
        
        // Only sync if we think we're disconnected but native says connected
        // This handles cases where app was backgrounded during connection
        if (_v2rayService.activeConfig == null) {
          debugPrint('?? Syncing state - native connected but we think disconnected');
          Future.delayed(const Duration(milliseconds: 500), () async {
            await _enhancedSyncWithVpnServiceState();
            notifyListeners();
          });
        }
        break;
        
      case 'disconnected':
      case 'stopped':
        // VPN disconnected from native side
        debugPrint('? Native reports VPN disconnected');
        
        // CRITICAL: Ignore native disconnect events during connection process
        // to prevent UI from resetting while we're connecting
        if (_isConnecting) {
          debugPrint('?? Ignoring native disconnect event during connection process');
          break;
        }
        
        // EXTRA SAFETY: If we just successfully connected (within last 10 seconds),
        // be extremely cautious about disconnect events
        if (_lastSuccessfulConnection != null) {
          final timeSinceConnection = DateTime.now().difference(_lastSuccessfulConnection!);
          if (timeSinceConnection.inMilliseconds < 10000) {
            debugPrint('?? SAFETY: Ignoring disconnect within 10s of successful connection');
            debugPrint('?? Time since connection: ${timeSinceConnection.inMilliseconds}ms');
            break;
          }
        }
        
        // ADDITIONAL FIX: Double-check that we actually have a connected config
        // and that we're not in the process of establishing a connection
        final hasConnectedConfig = _configs.any((c) => c.isConnected);
        final hasActiveConfig = _v2rayService.activeConfig != null;
        
        // If native says disconnected but we just connected, ignore this stale event
        if (hasActiveConfig && !hasConnectedConfig) {
          debugPrint('?? Ignoring stale disconnect event - activeConfig exists but configs not yet updated');
          break;
        }
        
        // Only update if we think we're connected and have an active config
        if (hasConnectedConfig || hasActiveConfig) {
          debugPrint('?? Processing native disconnect event...');
          // Run async operation properly with error handling
          Future(() async {
            try {
              for (var config in _configs) {
                config.isConnected = false;
              }
              await _v2rayService.saveConfigs(_configs);
              notifyListeners();
              debugPrint('? Configs updated after native disconnect event');
            } catch (e) {
              debugPrint('? Error updating configs after native disconnect: $e');
              // Still notify to update UI
              notifyListeners();
            }
          });
        } else {
          debugPrint('?? Ignoring disconnect event - already disconnected');
        }
        break;
        
      default:
        debugPrint('?? Unknown VPN status from native: $status');
        break;
    }
  }

  Future<void> _initialize() async {
    _setLoading(true);
    _isInitializing = true;
    notifyListeners();
    
    try {
      debugPrint('🚀 Starting app initialization...');
      
      // STEP 1: INSTANT UI - Load saved state and show immediately (0-50ms)
      await _loadSavedStateAndShowUI().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ Load saved state timeout, continuing...');
        },
      );
      debugPrint('✅ Saved state loaded and UI displayed');
      
      // STEP 2: QUICK SYNC - Check VPN status with timeout
      try {
        await _enhancedSyncWithVpnServiceState().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ VPN sync timeout, continuing...');
          },
        );
      } catch (e) {
        debugPrint('⚠️ VPN sync error: $e');
      }
      
      // STEP 3: Initialize service with timeout
      try {
        await _v2rayService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ Service init timeout, continuing...');
          },
        );
      } catch (e) {
        debugPrint('⚠️ Service init error: $e');
      }
      debugPrint('✅ Quick sync and service init complete');
      
      // STEP 2.5: Skip retry sync if it might cause hang
      // Only do quick check without blocking

      // Set up callback for notification disconnects
      _v2rayService.setDisconnectedCallback(() {
        _handleNotificationDisconnect();
      });

      // STEP 4: Load configurations from storage (already loaded in STEP 1)
      // Skip if already loaded in _loadSavedStateAndShowUI
      if (_configs.isEmpty) {
        await loadConfigs();
        debugPrint('? Configs loaded from storage: ${_configs.length} servers');
      } else {
        debugPrint('? Configs already loaded: ${_configs.length} servers');
      }

      // STEP 5: Fetch fresh servers from GitHub with timeout
      if (_configs.isEmpty) {
        debugPrint('📡 No cached servers, fetching from GitHub...');
        _isLoadingServers = true;
        notifyListeners();
        
        try {
          await fetchServers(customUrl: 'https://raw.githubusercontent.com/cverhud/v2ray-sub/refs/heads/main/sub2.txt')
            .timeout(const Duration(seconds: 10));
          debugPrint('✅ Fresh servers fetched: ${_configs.length} servers');
        } catch (e) {
          debugPrint('⚠️ Server fetch failed/timeout: $e');
        }
        
        _isLoadingServers = false;
        notifyListeners();
      } else {
        debugPrint('✅ Using cached servers (${_configs.length} servers)');
        
        // Fetch in background without blocking
        fetchServers(customUrl: 'https://raw.githubusercontent.com/cverhud/v2ray-sub/refs/heads/main/sub2.txt')
          .timeout(const Duration(seconds: 15))
          .then((_) => debugPrint('✅ Background server update complete'))
          .catchError((e) => debugPrint('⚠️ Background update failed: $e'));
      }
      
      // STEP 6: Skip final sync - already done above
      
      // STEP 7: Smart server selection logic
      if (_configs.isNotEmpty) {
        final hasConnectedConfig = _configs.any((c) => c.isConnected);
        
        if (hasConnectedConfig) {
          _selectedConfig = _configs.firstWhere((c) => c.isConnected);
          debugPrint('✅ Keeping connected server: ${_selectedConfig?.remark}');
        } else {
          try {
            final savedServer = await _loadSelectedServer().timeout(const Duration(seconds: 2));
            if (savedServer != null) {
              _selectedConfig = savedServer;
              debugPrint('✅ Restored saved server: ${_selectedConfig?.remark}');
            } else if (_selectedConfig == null) {
              _selectedConfig = V2RayConfig.smartConnect();
              debugPrint('✅ Auto-selected Smart Connect as default');
            }
          } catch (e) {
            _selectedConfig = V2RayConfig.smartConnect();
            debugPrint('⚠️ Load saved server failed, using Smart Connect');
          }
        }
        notifyListeners();
      }
      
      debugPrint('🏁 Initialization complete');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize: $e');
      _setError('Failed to initialize: $e');
    } finally {
      // CRITICAL: Always finish initialization even on error
      _setLoading(false);
      _isInitializing = false;
      notifyListeners();
      debugPrint('🏁 Initialization finally block executed');
    }
  }
  
  // Note: Removed _loadSelectedServer and _saveSelectedServer methods
  // We always auto-select the first server on app start (unless already connected)
  // User selection is temporary and resets after disconnect
  
  // OPTIMIZED: Fast VPN state sync - prevents UI freeze
  Future<void> _enhancedSyncWithVpnServiceState() async {
    try {
      debugPrint('🔄 Quick VPN state sync...');
      
      // STEP 1: Quick memory check first (instant, no I/O)
      final activeConfig = _v2rayService.activeConfig;
      if (activeConfig != null) {
        debugPrint('✅ Active config in memory: ${activeConfig.remark}');
        _syncConfigState(activeConfig);
        return;
      }
      
      // STEP 2: Quick status check with very short timeout
      bool isConnected = false;
      try {
        isConnected = await _v2rayService.isActuallyConnected()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('⏱️ Status check timeout: $e');
        // Use saved state as fallback
        isConnected = _configs.any((c) => c.isConnected);
      }
      
      if (isConnected) {
        debugPrint('✅ VPN connected, syncing...');
        // Try to restore config from saved state
        final savedConfig = await _loadSavedConnectionState();
        if (savedConfig != null) {
          _syncConfigState(savedConfig);
        }
      } else {
        debugPrint('❌ VPN disconnected');
        // Clear all connection states
        for (var config in _configs) {
          config.isConnected = false;
        }
      }
      
      // Save in background (fire and forget)
      _v2rayService.saveConfigs(_configs).catchError((_) {});
      
      debugPrint('✅ Sync complete');
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      // Keep existing state on error
    }
  }
  
  // Helper: Sync config state with active config
  void _syncConfigState(V2RayConfig activeConfig) {
    String? matchedId;
    
    // Find matching config
    for (var config in _configs) {
      if (config.fullConfig == activeConfig.fullConfig ||
          (config.address == activeConfig.address && config.port == activeConfig.port)) {
        matchedId = config.id;
        break;
      }
    }
    
    // Update states
    for (var config in _configs) {
      config.isConnected = (config.id == matchedId);
      if (config.isConnected) {
        _selectedConfig = config;
      }
    }
    
    // If no match found, add active config
    if (matchedId == null && !_configs.any((c) => c.id == activeConfig.id)) {
      activeConfig.isConnected = true;
      _configs.add(activeConfig);
      _selectedConfig = activeConfig;
    }
  }

  Future<void> loadConfigs() async {
    _setLoading(true);
    try {
      _configs = await _v2rayService.loadConfigs();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load configurations: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchServers({required String customUrl}) async {
    _isLoadingServers = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Fetch servers from service using the provided custom URL
      final servers = await _serverService.fetchServers(customUrl: customUrl);

      if (servers.isNotEmpty) {
        // Get all subscription config IDs to preserve them
        final subscriptionConfigIds = <String>{};
        for (var subscription in _subscriptions) {
          subscriptionConfigIds.addAll(subscription.configIds);
        }

        // Clear ping cache for default servers (non-subscription servers)
        for (var config in _configs) {
          if (!subscriptionConfigIds.contains(config.id)) {
            _v2rayService.clearPingCache(configId: config.id);
          }
        }

        // Keep existing subscription configs
        final subscriptionConfigs = _configs
            .where((c) => subscriptionConfigIds.contains(c.id))
            .toList();

        // Add default servers to the configs list
        _configs = [...subscriptionConfigs, ...servers];

        // Save configs and update UI immediately to show servers
        await _v2rayService.saveConfigs(_configs);

        // Mark loading as complete
        _isLoadingServers = false;
        notifyListeners();

        // Server delay functionality removed as requested
      } else {
        // If no servers found online, try to load from local storage
        _configs = await _v2rayService.loadConfigs();
      }
    } catch (e) {
      _setError('Failed to fetch servers: $e');
      // Try to load from local storage as fallback
      _configs = await _v2rayService.loadConfigs();
      notifyListeners();
    } finally {
      _isLoadingServers = false;
      notifyListeners();
    }
  }

  // Subscription feature disabled - using GitHub servers only
  Future<void> loadSubscriptions() async {
    // No-op: Subscriptions disabled
  }

  Future<void> addConfig(V2RayConfig config) async {
    // Add config and display it immediately (avoid duplicates)
    if (!_configs.any((c) => c.id == config.id)) {
      _configs.add(config);
    }

    // Save the configuration immediately to display it
    await _v2rayService.saveConfigs(_configs);
    notifyListeners();
  }

  Future<void> removeConfig(V2RayConfig config) async {
    try {
      _configs.removeWhere((c) => c.id == config.id);

      // Also remove from subscriptions if the config is part of any subscription
      for (int i = 0; i < _subscriptions.length; i++) {
        final subscription = _subscriptions[i];
        if (subscription.configIds.contains(config.id)) {
          final updatedConfigIds = List<String>.from(subscription.configIds)
            ..remove(config.id);
          _subscriptions[i] = subscription.copyWith(
            configIds: updatedConfigIds,
          );
        }
      }

      // If the deleted config was selected, clear the selection
      if (_selectedConfig?.id == config.id) {
        _selectedConfig = null;
      }

      await _v2rayService.saveConfigs(_configs);
      await _v2rayService.saveSubscriptions(_subscriptions);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete configuration: $e');
    }
  }

  Future<V2RayConfig?> importConfigFromText(String configText) async {
    try {
      // Try to parse the configuration
      final config = await _v2rayService.parseSubscriptionConfig(configText);
      if (config == null) {
        throw Exception('Invalid configuration format');
      }

      // Add the config to the list
      await addConfig(config);

      return config;
    } catch (e) {
      _setError('Failed to import configuration: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Cancel debounce timer
    _notifyDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Remove listener from V2RayService
    _v2rayService.removeListener(_onV2RayServiceChanged);
    // Cancel VPN status event subscription
    _vpnStatusSubscription?.cancel();
    // Dispose the service to stop monitoring
    _v2rayService.dispose();
    // Disconnect if connected when disposing (fire and forget - no await in dispose)
    if (_v2rayService.activeConfig != null) {
      // Fire and forget - dispose can't be async
      _v2rayService.disconnect().catchError((e) {
        debugPrint('Error disconnecting in dispose: $e');
      });
    }
    super.dispose();
  }

  Future<void> addSubscription(String name, String url) async {
    // Disabled: Subscriptions not supported
    _setError('Subscription feature is disabled');
  }

  Future<void> updateSubscription(Subscription subscription) async {
    // Disabled: Subscriptions not supported
    _setError('Subscription feature is disabled');
  }
  
  // Update subscription info without refreshing servers
  Future<void> updateSubscriptionInfo(Subscription subscription) async {
    // Disabled: Subscriptions not supported
    _setError('Subscription feature is disabled');
  }
  
  // Update all subscriptions
  Future<void> updateAllSubscriptions() async {
    // Disabled: Subscriptions not supported
    return;
    /*
    _setLoading(true);
    _errorMessage = '';
    _isLoadingServers = true;
    notifyListeners();

    // Clear all ping cache before updating subscriptions
    _v2rayService.clearPingCache();

    try {
      // Make a copy to avoid modification during iteration
      final subscriptionsCopy = List<Subscription>.from(_subscriptions);
      bool anyUpdated = false;
      List<String> failedSubscriptions = [];

      for (final subscription in subscriptionsCopy) {
        try {
          // Skip empty or invalid subscriptions
          if (subscription.url.isEmpty) continue;

          final configs = await _v2rayService.parseSubscriptionUrl(
            subscription.url,
          );

          // Remove old configs for this subscription
          _configs.removeWhere((c) => subscription.configIds.contains(c.id));

          // Add new configs (avoid duplicates by checking ID)
          for (var config in configs) {
            if (!_configs.any((c) => c.id == config.id)) {
              _configs.add(config);
            }
          }

          final newConfigIds = configs.map((c) => c.id).toList();

          // Update subscription
          final index = _subscriptions.indexWhere(
            (s) => s.id == subscription.id,
          );
          if (index != -1) {
            _subscriptions[index] = subscription.copyWith(
              lastUpdated: DateTime.now(),
              configIds: newConfigIds,
            );
            anyUpdated = true;
          }
        } catch (e) {
          // Record failed subscription
          failedSubscriptions.add(subscription.name);
          // Error updating subscription
        }
      }

      // Save all changes at once to reduce disk operations
      if (anyUpdated) {
        await _v2rayService.saveConfigs(_configs);
        await _v2rayService.saveSubscriptions(_subscriptions);
      }

      // Set error message if any subscriptions failed
      if (failedSubscriptions.isNotEmpty) {
        if (failedSubscriptions.length == _subscriptions.length) {
          // All subscriptions failed - likely a network issue
          _setError(
            'Failed to update subscriptions: Network error or invalid URLs',
          );
        } else {
          // Some subscriptions failed
          _setError('Failed to update: ${failedSubscriptions.join(', ')}');
        }
      }

      _isLoadingServers = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update all subscriptions: $e');
    } finally {
      _setLoading(false);
      _isLoadingServers = false;
    }
    */
  }

  Future<void> removeSubscription(Subscription subscription) async {
    // Remove configs associated with this subscription
    _configs.removeWhere((c) => subscription.configIds.contains(c.id));

    // Remove subscription
    _subscriptions.removeWhere((s) => s.id == subscription.id);

    await _v2rayService.saveConfigs(_configs);
    await _v2rayService.saveSubscriptions(_subscriptions);
    notifyListeners();
  }

  Future<bool> connectToServer(V2RayConfig config) async {
    debugPrint('🔌 Connecting to: ${config.remark}');
    
    if (config.address.isEmpty || config.port <= 0) {
      _setError('Invalid server configuration');
      return false;
    }
    
    _isConnecting = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Disconnect from current server if connected
      if (_v2rayService.activeConfig != null) {
        try {
          await _v2rayService.disconnect();
        } catch (_) {}
      }

      // Connect with timeout
      final success = await _v2rayService.connect(config).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Connection timeout');
          return false;
        },
      );

      if (success) {
        _lastSuccessfulConnection = DateTime.now();
        _errorMessage = '';
        
        // Wait for connection to stabilize
        await Future.delayed(const Duration(seconds: 1));
        
        // Update config states
        for (var c in _configs) {
          c.isConnected = (c.id == config.id);
        }
        _selectedConfig = config;
        
        // Save configs
        await _v2rayService.saveConfigs(_configs);
        _saveConnectionState(config).catchError((_) {});
        
        debugPrint('✅ Connected to ${config.remark}');
        return true;
      } else {
        _setError('Connection failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      _setError('Connection error: $e');
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isConnecting = true;
    notifyListeners();

    try {
      // Log analytics event for disconnection
      final activeConfig = _v2rayService.activeConfig;
      
      if (activeConfig != null) {
        try {
          await _analyticsService.logVpnDisconnect(
            serverName: activeConfig.remark,
            durationSeconds: _v2rayService.connectedSeconds,
            uploadBytes: _v2rayService.uploadBytes,
            downloadBytes: _v2rayService.downloadBytes,
            disconnectReason: 'user_action',
          );
        } catch (e) {
          // Analytics logging failed, ignore
        }
      }
      
      await _v2rayService.disconnect();
      statusPingOnly = false;
      
      // Clear the grace period timer
      _lastSuccessfulConnection = null;
      
      // پاک کردن وضعیت اتصال ذخیره شده
      await _clearConnectionState();
      
      // Update config status
      for (int i = 0; i < _configs.length; i++) {
        _configs[i].isConnected = false;
      }

      // IMPORTANT: ALWAYS reset to Smart Connect after disconnect
      // User wants Smart Connect to be the default always
      _selectedConfig = V2RayConfig.smartConnect();
      _wasUsingSmartConnect = true;
      await _saveSelectedServer(_selectedConfig!);
      debugPrint('✅ Reset to Smart Connect after disconnect (always default)');

      // Persist the changes
      await _v2rayService.saveConfigs(_configs);
    } catch (e) {
      _setError('Error disconnecting: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // ==============================================================================
  // Connection State Persistence (Fix for UI sync issues after app kill)
  // ==============================================================================

  Future<void> _saveConnectionState(V2RayConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_config_id', config.id);
      await prefs.setBool('connected_is_smart', _wasUsingSmartConnect);
      debugPrint('💾 Connection state saved: ID=${config.id}, Smart=$_wasUsingSmartConnect');
    } catch (e) {
      debugPrint('❌ Error saving connection state: $e');
    }
  }

  Future<void> _clearConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('connected_config_id');
      await prefs.remove('connected_is_smart');
      debugPrint('🗑️ Connection state cleared');
    } catch (e) {
      debugPrint('❌ Error clearing connection state: $e');
    }
  }

  Future<V2RayConfig?> _loadSavedConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configId = prefs.getString('connected_config_id');
      final wasSmart = prefs.getBool('connected_is_smart') ?? false;
      
      if (configId != null) {
        debugPrint('📂 Found saved connection state: ID=$configId, Smart=$wasSmart');
        
        // Restore smart connect flag
        _wasUsingSmartConnect = wasSmart;
        
        // Find config in list
        try {
          final config = _configs.firstWhere((c) => c.id == configId);
          return config;
        } catch (e) {
          debugPrint('⚠️ Saved config ID not found in current list');
          return null;
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading saved connection state: $e');
    }
    return null;
  }

  // Smart Connect: Test 7 servers and connect to fastest
  Future<bool> smartConnect({int maxServersToTest = 7}) async {
    if (_configs.isEmpty) {
      _setError('No servers available');
      return false;
    }

    if (_isConnecting) return false;

    _wasUsingSmartConnect = true;
    _isConnecting = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('🧠 Smart Connect: Testing $maxServersToTest servers...');
      
      final serversToTest = _configs.take(maxServersToTest).toList();
      
      // Use batch ping (non-blocking, runs in native code)
      debugPrint('📡 Batch pinging servers...');
      final pingResults = await _v2rayService.batchPingServers(serversToTest);
      
      // If batch ping failed completely, try servers directly
      if (pingResults.isEmpty) {
        debugPrint('⚠️ Batch ping failed, trying servers directly...');
        for (final server in serversToTest) {
          _isConnecting = false;
          notifyListeners();
          
          final success = await connectToServer(server);
          if (success) {
            _wasUsingSmartConnect = true;
            return true;
          }
        }
        _setError('Could not connect to any server');
        return false;
      }
      
      // Sort servers by ping (fastest first)
      final sortedServers = List<V2RayConfig>.from(serversToTest);
      sortedServers.sort((a, b) {
        final pingA = pingResults[a.id] ?? 99999;
        final pingB = pingResults[b.id] ?? 99999;
        return pingA.compareTo(pingB);
      });
      
      // Log ping results
      for (final server in sortedServers) {
        final ping = pingResults[server.id];
        debugPrint('📶 ${server.remark}: ${ping ?? "timeout"}ms');
      }
      
      // Try to connect to servers in order of ping (fastest first)
      for (final server in sortedServers) {
        final ping = pingResults[server.id];
        
        // Skip servers with no ping response
        if (ping == null || ping >= 9999) {
          debugPrint('⏭️ Skipping ${server.remark} (no response)');
          continue;
        }
        
        debugPrint('🔌 Connecting to ${server.remark} (${ping}ms)...');
        
        _isConnecting = false;
        notifyListeners();
        
        final success = await connectToServer(server);
        
        if (success) {
          _wasUsingSmartConnect = true;
          debugPrint('✅ Smart Connect success: ${server.remark}');
          return true;
        }
        
        debugPrint('❌ Failed: ${server.remark}, trying next...');
      }
      
      // If all pinged servers failed, try servers that had no ping response
      debugPrint('⚠️ All pinged servers failed, trying unresponsive servers...');
      for (final server in sortedServers) {
        final ping = pingResults[server.id];
        // Only try servers we skipped before (no ping response)
        if (ping != null && ping < 9999) continue;
        
        _isConnecting = false;
        notifyListeners();
        
        final success = await connectToServer(server);
        if (success) {
          _wasUsingSmartConnect = true;
          return true;
        }
      }
      
      _setError('Could not connect to any server');
      return false;
    } catch (e) {
      debugPrint('❌ Smart Connect error: $e');
      _setError('Smart Connect failed: $e');
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Removed testServerDelay method as requested

  // Removed pingServer and pingAllServers methods as requested

  Future<void> selectConfig(V2RayConfig config) async {
    debugPrint('🔧 selectConfig called for: ${config.remark}');
    debugPrint('   isSmartConnect: ${config.isSmartConnect}');
    debugPrint('   config.id: ${config.id}');
    
    _selectedConfig = config;
    
    // Track if user selected Smart Connect or a manual server
    if (config.isSmartConnect) {
      _wasUsingSmartConnect = true;
      debugPrint('✅ User selected Smart Connect');
    } else {
      _wasUsingSmartConnect = false;
      debugPrint('✅ User selected manual server: ${config.remark}');
    }
    
    // IMPORTANT: Save selected server to persist across app restarts
    await _saveSelectedServer(config);
    debugPrint('💾 Selected and saved server: ${config.remark}');
    
    // Log server selection analytics
    try {
      await _analyticsService.logServerSelection(
        serverName: config.remark,
        selectionMethod: 'manual',
      );
    } catch (e) {
      // Analytics logging failed, ignore
    }
    
    notifyListeners();
    debugPrint('📢 notifyListeners called after selectConfig');
  }
  
  // Save selected server to SharedPreferences
  Future<void> _saveSelectedServer(V2RayConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_server_id', config.id);
      debugPrint('?? Saved selected server ID: ${config.id}');
    } catch (e) {
      debugPrint('? Error saving selected server: $e');
    }
  }
  
  // Load selected server from SharedPreferences
  Future<V2RayConfig?> _loadSelectedServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedServerId = prefs.getString('selected_server_id');
      
      if (selectedServerId != null) {
        // Check if Smart Connect was selected
        if (selectedServerId == 'smart_connect') {
          debugPrint('?? Loaded Smart Connect');
          return V2RayConfig.smartConnect();
        }
        
        // Try to find the saved server in configs
        if (_configs.isNotEmpty) {
          try {
            final server = _configs.firstWhere(
              (config) => config.id == selectedServerId,
            );
            debugPrint('?? Loaded selected server: ${server.remark}');
            return server;
          } catch (e) {
            debugPrint('?? Saved server not found in configs');
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('? Error loading selected server: $e');
      return null;
    }
  }

  // Proxy mode feature removed for simplification
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    _isLoadingServers = loading; // Update server loading state as well
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  Future<void> _handleNotificationDisconnect() async {
    debugPrint('?? Notification disconnect triggered');
    
    // Actually disconnect the VPN service
    await _v2rayService.disconnect();
    
    // Update config status when disconnected from notification
    for (int i = 0; i < _configs.length; i++) {
      _configs[i].isConnected = false;
    }

    // IMPORTANT: Keep _selectedConfig so user can easily reconnect
    // Don't set _selectedConfig = null
    debugPrint('?? Keeping selected config: ${_selectedConfig?.remark}');

    // Notify listeners immediately to update UI in real-time
    notifyListeners();

    // Persist the changes
    try {
      await _v2rayService.saveConfigs(_configs);
      notifyListeners();
      debugPrint('? Configs saved after notification disconnect');
    } catch (e) {
      debugPrint('? Error saving configs after notification disconnect: $e');
      notifyListeners();
    }
  }

  
  // OPTIMISTIC UI: Load saved state immediately for instant UI display
  Future<void> _loadSavedStateAndShowUI() async {
    try {
      debugPrint('?? Loading saved state for optimistic UI...');
      
      // Load configs from storage immediately (very fast, no network)
      final savedConfigs = await _v2rayService.loadConfigs();
      if (savedConfigs.isNotEmpty) {
        _configs = savedConfigs;
        debugPrint('?? Loaded ${_configs.length} saved configs');
        
        // بازیابی وضعیت اتصال ذخیره شده
        await _loadSavedConnectionState();
        
        // Try to load saved selected server first
        final prefs = await SharedPreferences.getInstance();
        final savedServerId = prefs.getString('selected_server_id');
        
        if (savedServerId != null) {
          // Try to find the saved selected server
          try {
            final savedServerIndex = _configs.indexWhere(
              (config) => config.id == savedServerId,
            );
            if (savedServerIndex != -1) {
              _selectedConfig = _configs[savedServerIndex];
              debugPrint('?? Restored selected server: ${_selectedConfig?.remark}');
            } else {
              debugPrint('?? Saved server not found in configs');
            }
          } catch (e) {
            debugPrint('?? Could not restore saved server: $e');
          }
        }
        
        // Check if any config is marked as connected
        final connectedConfigIndex = _configs.indexWhere((c) => c.isConnected);
        if (connectedConfigIndex != -1) {
          _selectedConfig = _configs[connectedConfigIndex];
          debugPrint('?? Found connected config: ${_selectedConfig?.remark}');
          
          // CRITICAL: Force service to restore activeConfig immediately
          // This ensures activeConfig is available when UI checks it
          if (_v2rayService.activeConfig == null) {
            debugPrint('?? Service activeConfig is null, triggering restore...');
            // Try to restore immediately in background
            _v2rayService.initialize().then((_) {
              debugPrint('? Service initialized, checking activeConfig...');
              if (_v2rayService.activeConfig != null) {
                debugPrint('? ActiveConfig restored: ${_v2rayService.activeConfig?.remark}');
                notifyListeners();
              } else {
                debugPrint('?? ActiveConfig still null after init');
              }
            }).catchError((e) {
              debugPrint('? Error initializing service: $e');
            });
          }
        }
        
        // Notify UI immediately with saved state
        notifyListeners();
        debugPrint('? Optimistic UI loaded and displayed');
      } else {
        debugPrint('?? No saved configs found');
      }
    } catch (e) {
      debugPrint('? Error loading saved state: $e');
      // Error loading saved state, continue with empty list
    }
  }
  
  // Method to fetch connection status from the notification
  Future<void> fetchNotificationStatus() async {
    try {
      // Get the actual connection status from the service
      final isActuallyConnected = await _v2rayService.isActuallyConnected();
      final activeConfig = _v2rayService.activeConfig;

      debugPrint(
        'Fetching notification status - Connected: $isActuallyConnected, Active config: ${activeConfig?.remark}',
      );

      // Update all configs based on the actual status
      bool statusChanged = false;

      if (activeConfig != null && isActuallyConnected) {
        // VPN is connected, update the matching config
        for (int i = 0; i < _configs.length; i++) {
          bool shouldBeConnected = false;

          // Find the matching config by comparing the server details
          shouldBeConnected =
              _configs[i].fullConfig == activeConfig.fullConfig ||
              (_configs[i].address == activeConfig.address &&
                  _configs[i].port == activeConfig.port);

          if (_configs[i].isConnected != shouldBeConnected) {
            _configs[i].isConnected = shouldBeConnected;
            statusChanged = true;

            if (shouldBeConnected) {
              _selectedConfig = _configs[i];
              debugPrint('Updated config ${_configs[i].remark} to connected');
            }
          }
        }
      } else {
        // VPN is not connected, clear all connected states
        for (int i = 0; i < _configs.length; i++) {
          if (_configs[i].isConnected) {
            _configs[i].isConnected = false;
            statusChanged = true;
            debugPrint('Updated config ${_configs[i].remark} to disconnected');
          }
        }
        if (statusChanged) {
          // Keep selected config for easy reconnection
          // Don't set _selectedConfig to null
        }
      }

      if (statusChanged) {
        await _v2rayService.saveConfigs(_configs);
        notifyListeners();
        debugPrint('Connection status updated from notification check');
      }
    } catch (e) {
      debugPrint('Error fetching notification status: $e');
      // Don't change connection state on errors
    }
  }

  /// Force check VPN status - OPTIMIZED to prevent freeze
  Future<void> forceCheckVpnStatus() async {
    // Skip if checked recently
    if (_lastStatusCheck != null) {
      final timeSince = DateTime.now().difference(_lastStatusCheck!);
      if (timeSince.inSeconds < 2) {
        debugPrint('⏭️ Skip status check (${timeSince.inSeconds}s ago)');
        return;
      }
    }
    
    try {
      debugPrint('🔄 Quick VPN status check...');
      _lastStatusCheck = DateTime.now();
      
      // STEP 1: Check memory state first (instant)
      if (_v2rayService.activeConfig != null) {
        debugPrint('✅ Connected (memory check)');
        _syncConfigState(_v2rayService.activeConfig!);
        notifyListeners();
        return;
      }
      
      // STEP 2: Quick service check with SHORT timeout
      bool isConnected = false;
      try {
        isConnected = await _v2rayService.isActuallyConnected()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('⏱️ Status check timeout: $e');
        isConnected = _configs.any((c) => c.isConnected);
      }
      
      debugPrint('🔎 VPN connected: $isConnected');
      
      if (isConnected) {
        await _enhancedSyncWithVpnServiceState();
        _errorMessage = '';
      } else {
        // Clear connection states
        for (var config in _configs) {
          config.isConnected = false;
        }
        // Save in background
        _v2rayService.saveConfigs(_configs).catchError((_) {});
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Status check error: $e');
      notifyListeners();
    }
  }
  
  // Method to manually check connection status
  Future<void> checkConnectionStatus() async {
    try {
      debugPrint('?? Checking connection status...');
      
      // Always check the actual VPN connection status
      final isActuallyConnected = await _v2rayService.isActuallyConnected();
      final activeConfig = _v2rayService.activeConfig;
      
      debugPrint('?? VPN is actually connected: $isActuallyConnected');
      debugPrint('?? Active config: ${activeConfig?.remark}');
      
      bool statusChanged = false;
      
      if (isActuallyConnected && activeConfig != null) {
        // VPN is actually connected - ensure UI shows this
        debugPrint('? VPN is connected, syncing UI...');
        bool foundMatch = false;
        
        for (int i = 0; i < _configs.length; i++) {
          bool shouldBeConnected = _configs[i].fullConfig == activeConfig.fullConfig ||
              (_configs[i].address == activeConfig.address &&
               _configs[i].port == activeConfig.port);
          
          if (_configs[i].isConnected != shouldBeConnected) {
            _configs[i].isConnected = shouldBeConnected;
            statusChanged = true;
            if (shouldBeConnected) {
              _selectedConfig = _configs[i];
              foundMatch = true;
              debugPrint('? Found matching config: ${_configs[i].remark}');
            }
          } else if (shouldBeConnected) {
            foundMatch = true;
            _selectedConfig = _configs[i];
          }
        }
        
        // If no match found in existing configs, add the active config temporarily
        if (!foundMatch) {
          bool exists = _configs.any((c) => c.id == activeConfig.id);
          if (!exists) {
            debugPrint('?? Active config not in list, adding it');
            activeConfig.isConnected = true;
            _configs.insert(0, activeConfig);
            _selectedConfig = activeConfig;
            statusChanged = true;
          }
        }
      } else {
        // VPN is NOT connected - ensure all configs show disconnected
        debugPrint('? VPN is not connected, clearing all connection states');
        for (int i = 0; i < _configs.length; i++) {
          if (_configs[i].isConnected) {
            _configs[i].isConnected = false;
            statusChanged = true;
          }
        }
        // Keep selected config for easy reconnection
      }
      
      if (statusChanged) {
        await _v2rayService.saveConfigs(_configs);
        debugPrint('?? Connection status saved');
      }
      
      // Always notify to refresh UI
      notifyListeners();
      debugPrint('?? UI updated with connection status');
    } catch (e) {
      debugPrint('? Error checking connection status: $e');
      // Don't change connection state on errors, but still notify UI
      notifyListeners();
    }
  }
}
