import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2ray_config.dart';
import '../models/subscription.dart';
import '../services/v2ray_service.dart';
import '../services/server_service.dart';
import '../services/tiksar_plus_service.dart';
import '../services/analytics_service.dart';

class V2RayProvider with ChangeNotifier, WidgetsBindingObserver {
  final V2RayService _v2rayService = V2RayService();
  final ServerService _serverService = ServerService();
  final TiksarPlusService _tiksarPlusService = TiksarPlusService();
  final AnalyticsService _analyticsService = AnalyticsService();
  bool statusPingOnly = false;
  List<V2RayConfig> _configs = [];
  List<Subscription> _subscriptions = []; // Empty - subscriptions disabled
  V2RayConfig? _selectedConfig;
  bool _isConnecting = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoadingServers = false;
  bool _isProxyMode = false;
  bool _isInitializing = true; // Track initialization state
  DateTime? _lastSuccessfulConnection; // Track last successful connection time
  bool _isAutoMode = true; // Auto mode is always enabled (Smart/Plus selection)
  String _serverSource = TiksarPlusService.defaultSource; // Current server source (smart or plus)
  
  // Method channel for VPN control
  static const platform = MethodChannel('com.tiksarvpn.app/vpn_control');
  
  // Event channel for receiving VPN status updates from native side
  static const EventChannel _vpnStatusEventChannel = EventChannel('com.tiksarvpn.app/vpn_status_events');
  StreamSubscription? _vpnStatusSubscription;

  List<V2RayConfig> get configs => _configs;
  List<Subscription> get subscriptions => _subscriptions;
  V2RayConfig? get selectedConfig => _selectedConfig;
  V2RayConfig? get activeConfig => _v2rayService.activeConfig;
  bool get isConnecting => _isConnecting;
  bool get isLoading => _isLoading;
  bool get isLoadingServers => _isLoadingServers;
  String get errorMessage => _errorMessage;
  V2RayService get v2rayService => _v2rayService;
  bool get isProxyMode => _isProxyMode;
  bool get isInitializing => _isInitializing;
  bool get isAutoMode => _isAutoMode; // Getter for automatic mode
  String get serverSource => _serverSource; // Current server source

  // Expose V2Ray status for real-time traffic monitoring
  V2RayStatus? get currentStatus => _v2rayService.currentStatus;
  
  // Get only manual servers (user's servers) - hide auto servers from UI
  List<V2RayConfig> get manualServers {
    return _configs.where((c) => c.serverSource == 'manual').toList();
  }
  
  // Get only auto servers (Tiksar Plus servers) - internal use only
  List<V2RayConfig> get autoServers {
    return _configs.where((c) => c.serverSource == 'auto').toList();
  }
  
  // Get friendly name for current server source
  String get serverSourceName {
    if (_serverSource == TiksarPlusService.sourceSmart) {
      return 'Tiksar Smart';
    } else {
      return 'Tiksar Plus';
    }
  }

  V2RayProvider() {
    WidgetsBinding.instance.addObserver(this);
    // Listen to V2RayService changes to update UI automatically
    _v2rayService.addListener(_onV2RayServiceChanged);
    
    // Set up VPN status event listener (inspired by defyxVPN)
    _setupVpnStatusListener();
    
    _initialize();
    
    // Set up method channel handler for notification disconnect
    platform.setMethodCallHandler(_handleMethodCall);
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
    // When V2RayService state changes, notify our listeners
    notifyListeners();
  }
  
  /// Setup VPN status event listener (inspired by defyxVPN)
  /// This listens to real-time VPN status changes from native side
  void _setupVpnStatusListener() {
    try {
      debugPrint('📡 Setting up VPN status event listener...');
      
      _vpnStatusSubscription = _vpnStatusEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final Map<String, dynamic> statusEvent = Map<String, dynamic>.from(event);
            
            if (statusEvent.containsKey('status')) {
              final String vpnStatus = statusEvent['status'] as String;
              debugPrint('📡 VPN status event received: $vpnStatus');
              
              // Handle VPN status changes from native side
              _handleNativeVpnStatusChange(vpnStatus);
            }
          }
        },
        onError: (dynamic error) {
          debugPrint('❌ Error from VPN status event channel: $error');
        },
      );
      
      debugPrint('✅ VPN status listener setup complete');
    } catch (e) {
      debugPrint('⚠️ Could not setup VPN status listener: $e');
      // Continue without event listener - not critical
    }
  }
  
  /// Handle VPN status changes from native side
  void _handleNativeVpnStatusChange(String status) {
    debugPrint('🔄 Handling native VPN status change: $status');
    
    // CRITICAL FIX: Ignore ALL native events for 8 seconds after successful connection
    // This prevents race conditions where native sends stale events that reset UI
    // Using milliseconds to catch events that arrive within first second
    if (_lastSuccessfulConnection != null) {
      final timeSinceConnection = DateTime.now().difference(_lastSuccessfulConnection!);
      if (timeSinceConnection.inMilliseconds < 8000) {
        debugPrint('⏭️ Ignoring ALL native events (within 8s grace period after connection)');
        debugPrint('⏭️ Time since connection: ${timeSinceConnection.inMilliseconds}ms');
        return;
      }
    }
    
    switch (status.toLowerCase()) {
      case 'connected':
        // VPN connected from native side
        debugPrint('✅ Native reports VPN connected');
        
        // If we're already in connection process, skip sync to avoid UI reset
        if (_isConnecting) {
          debugPrint('⏭️ Skipping sync - already in connection process');
          break;
        }
        
        // Only sync if we think we're disconnected but native says connected
        // This handles cases where app was backgrounded during connection
        if (_v2rayService.activeConfig == null) {
          debugPrint('🔄 Syncing state - native connected but we think disconnected');
          Future.delayed(const Duration(milliseconds: 500), () async {
            await _enhancedSyncWithVpnServiceState();
            notifyListeners();
          });
        }
        break;
        
      case 'disconnected':
      case 'stopped':
        // VPN disconnected from native side
        debugPrint('❌ Native reports VPN disconnected');
        
        // CRITICAL: Ignore native disconnect events during connection process
        // to prevent UI from resetting while we're connecting
        if (_isConnecting) {
          debugPrint('⏭️ Ignoring native disconnect event during connection process');
          break;
        }
        
        // EXTRA SAFETY: If we just successfully connected (within last 10 seconds),
        // be extremely cautious about disconnect events
        if (_lastSuccessfulConnection != null) {
          final timeSinceConnection = DateTime.now().difference(_lastSuccessfulConnection!);
          if (timeSinceConnection.inMilliseconds < 10000) {
            debugPrint('⏭️ SAFETY: Ignoring disconnect within 10s of successful connection');
            debugPrint('⏭️ Time since connection: ${timeSinceConnection.inMilliseconds}ms');
            break;
          }
        }
        
        // ADDITIONAL FIX: Double-check that we actually have a connected config
        // and that we're not in the process of establishing a connection
        final hasConnectedConfig = _configs.any((c) => c.isConnected);
        final hasActiveConfig = _v2rayService.activeConfig != null;
        
        // If native says disconnected but we just connected, ignore this stale event
        if (hasActiveConfig && !hasConnectedConfig) {
          debugPrint('⏭️ Ignoring stale disconnect event - activeConfig exists but configs not yet updated');
          break;
        }
        
        // Only update if we think we're connected and have an active config
        if (hasConnectedConfig || hasActiveConfig) {
          debugPrint('🔄 Processing native disconnect event...');
          // Run async operation properly with error handling
          Future(() async {
            try {
              for (var config in _configs) {
                config.isConnected = false;
              }
              await _v2rayService.saveConfigs(_configs);
              notifyListeners();
              debugPrint('✅ Configs updated after native disconnect event');
            } catch (e) {
              debugPrint('❌ Error updating configs after native disconnect: $e');
              // Still notify to update UI
              notifyListeners();
            }
          });
        } else {
          debugPrint('⏭️ Ignoring disconnect event - already disconnected');
        }
        break;
        
      default:
        debugPrint('ℹ️ Unknown VPN status from native: $status');
        break;
    }
  }

  Future<void> _initialize() async {
    _setLoading(true);
    _isInitializing = true;
    notifyListeners();
    
    try {
      debugPrint('🚀 Starting app initialization...');
      
      // OPTIMISTIC UI: Load saved config immediately and show UI first
      await _loadSavedStateAndShowUI();
      debugPrint('✅ Saved state loaded and UI displayed');
      
      // Initialize service
      await _v2rayService.initialize();
      debugPrint('✅ V2Ray service initialized');

      // Set up callback for notification disconnects
      _v2rayService.setDisconnectedCallback(() {
        _handleNotificationDisconnect();
      });

      // Load configurations first
      await loadConfigs();
      debugPrint('✅ Configs loaded: ${_configs.length} servers');

      // Note: Subscription loading skipped - only Smart/Plus servers are used
      // await loadSubscriptions();
      
      // Load proxy mode and server source settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _isProxyMode = prefs.getBool('proxy_mode_enabled') ?? false;
      _serverSource = prefs.getString('server_source') ?? TiksarPlusService.defaultSource;
      debugPrint('✅ Settings loaded - Proxy: $_isProxyMode, Source: $_serverSource');

      // Auto mode is always enabled - fetch servers automatically from selected source
      try {
        await _fetchTiksarPlusServers(source: _serverSource);
        debugPrint('✅ ${serverSourceName} loaded');
      } catch (e) {
        debugPrint('⚠️ Failed to load servers: $e');
      }

      // Note: Subscription management removed - only Smart/Plus servers are used

      // CRITICAL FIX: Enhanced synchronization with actual VPN service state
      // This method checks VPN status and updates all configs accordingly
      await _enhancedSyncWithVpnServiceState();
      
      // Always auto-select first server (unless already connected)
      if (_configs.isNotEmpty) {
        final hasConnectedConfig = _configs.any((c) => c.isConnected);
        
        if (hasConnectedConfig) {
          // If already connected, keep the connected server as selected
          _selectedConfig = _configs.firstWhere((c) => c.isConnected);
          debugPrint('✅ Keeping connected server: ${_selectedConfig?.remark}');
        } else {
          // Not connected, always select first server
          _selectedConfig = _configs.first;
          debugPrint('✅ Auto-selected first server: ${_selectedConfig?.remark}');
        }
        notifyListeners();
      }

      debugPrint('✅ Initialization complete');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize: $e');
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
      _isInitializing = false;
      notifyListeners();
    }
  }
  
  // Note: Removed _loadSelectedServer and _saveSelectedServer methods
  // We always auto-select the first server on app start (unless already connected)
  // User selection is temporary and resets after disconnect
  
  // CRITICAL FIX: Enhanced method to synchronize with actual VPN service state
  Future<void> _enhancedSyncWithVpnServiceState() async {
    try {
      debugPrint('🔄 Starting VPN state synchronization...');
      
      // Check if VPN is actually running using the improved method
      final isActuallyConnected = await _v2rayService.isActuallyConnected();
      debugPrint('🔍 VPN actually connected: $isActuallyConnected');
      
      // IMPORTANT: Don't reset states before checking!
      // This prevents UI flicker when VPN is actually connected
      
      if (isActuallyConnected) {
        debugPrint('✅ VPN is running, synchronizing config states...');
        
        // VPN is actually running, synchronizing config states
        final activeConfigFromService = _v2rayService.activeConfig;
        debugPrint('🔍 Active config from service: ${activeConfigFromService?.remark}');
        
        if (activeConfigFromService != null) {
          bool configFound = false;
          String? matchedConfigId;
          
          // Try to find exact matching config
          for (var config in _configs) {
            if (config.fullConfig == activeConfigFromService.fullConfig) {
              matchedConfigId = config.id;
              configFound = true;
              debugPrint('✅ Found exact matching config: ${config.remark}');
              break;
            }
          }
          
          // If exact match not found, try matching by address and port
          if (!configFound) {
            debugPrint('⚠️ Exact match not found, trying address/port match...');
            for (var config in _configs) {
              if (config.address == activeConfigFromService.address &&
                  config.port == activeConfigFromService.port) {
                matchedConfigId = config.id;
                configFound = true;
                debugPrint('✅ Found matching config by address/port: ${config.remark}');
                break;
              }
            }
          }
          
          // Now update all configs: only matched one should be connected
          for (var config in _configs) {
            bool shouldBeConnected = (config.id == matchedConfigId);
            if (config.isConnected != shouldBeConnected) {
              config.isConnected = shouldBeConnected;
              if (shouldBeConnected) {
                _selectedConfig = config;
              }
            } else if (shouldBeConnected) {
              _selectedConfig = config;
            }
          }
          
          // If still no matching config found, add the active config temporarily
          if (!configFound) {
            debugPrint('⚠️ No matching config found, adding active config temporarily');
            _configs.add(activeConfigFromService);
            activeConfigFromService.isConnected = true;
            _selectedConfig = activeConfigFromService;
            debugPrint('✅ Added and selected: ${activeConfigFromService.remark}');
          }
        } else {
          debugPrint('⚠️ VPN is running but no active config details from service');
          
          // VPN is running but we don't have the config details
          // Use the selected config from SharedPreferences if available
          String? selectedId;
          
          if (_selectedConfig != null) {
            // We have a selected config
            final selectedIndex = _configs.indexWhere((c) => c.id == _selectedConfig!.id);
            if (selectedIndex != -1) {
              selectedId = _selectedConfig!.id;
              debugPrint('✅ Will mark selected config as connected: ${_configs[selectedIndex].remark}');
            } else {
              // Selected config not in list, use first as fallback
              if (_configs.isNotEmpty) {
                selectedId = _configs.first.id;
                _selectedConfig = _configs.first;
                debugPrint('⚠️ Selected config not found, will use first: ${_configs.first.remark}');
              }
            }
          } else {
            // No selected config, use first as fallback
            if (_configs.isNotEmpty) {
              selectedId = _configs.first.id;
              _selectedConfig = _configs.first;
              debugPrint('⚠️ No selected config, will use first: ${_configs.first.remark}');
            }
          }
          
          // Now sync all configs: only selected one should be connected
          for (var config in _configs) {
            bool shouldBeConnected = (config.id == selectedId);
            if (config.isConnected != shouldBeConnected) {
              config.isConnected = shouldBeConnected;
            }
          }
        }
      } else {
        debugPrint('❌ VPN is NOT connected, clearing all connection states');
        
        // VPN is not actually connected, clearing connection states
        // Only update configs that are currently marked as connected
        bool anyWasConnected = false;
        for (var config in _configs) {
          if (config.isConnected) {
            config.isConnected = false;
            anyWasConnected = true;
          }
        }
        
        if (anyWasConnected) {
          debugPrint('✅ Cleared connection states (were connected, now disconnected)');
        } else {
          debugPrint('ℹ️ All configs already disconnected, no changes needed');
        }
        debugPrint('💾 Keeping selected config: ${_selectedConfig?.remark ?? "none"}');
        
        // Keep _selectedConfig so user can reconnect to the same server
        // Only clear isConnected flag, not the selection itself
        
        // Don't call disconnect if not connected - prevents errors
        // Just clear the state
      }
      
      // Save the synchronized state
      try {
        await _v2rayService.saveConfigs(_configs);
        debugPrint('💾 Synchronized state saved successfully');
      } catch (saveError) {
        debugPrint('⚠️ Error saving configs during sync: $saveError');
      }
      
      // Log final state
      debugPrint('📊 Final sync state:');
      debugPrint('   - Selected config: ${_selectedConfig?.remark ?? "none"}');
      debugPrint('   - Connected configs: ${_configs.where((c) => c.isConnected).map((c) => c.remark).join(", ")}');
      
    } catch (e) {
      debugPrint('❌ Error in synchronization: $e');
      // Error in synchronization, ensure clean state
      for (var config in _configs) {
        config.isConnected = false;
      }
      debugPrint('🔄 Cleared all connection states due to error');
      // Keep _selectedConfig even on error so user can try reconnecting
      // Don't set _selectedConfig = null
      debugPrint('💾 Keeping selected config: ${_selectedConfig?.remark ?? "none"}');
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

  // Subscription-based fetch disabled
  Future<void> fetchServers({required String customUrl}) async {
    debugPrint('⚠️ fetchServers called but subscription fetch is disabled');
    _setError('Manual server fetch is disabled. Only Smart/Plus servers are available.');
    return;
    /* DISABLED
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
    */ // END DISABLED
  }

  // Subscription management disabled - keeping method for compatibility
  Future<void> loadSubscriptions() async {
    // Subscriptions disabled - only Smart/Plus servers are used
    _subscriptions = [];
    return;
    
    /* DISABLED CODE
    _setLoading(true);
    try {
      _subscriptions = await _v2rayService.loadSubscriptions();

      // Create default subscription if no subscriptions exist
      if (_subscriptions.isEmpty) {
        final defaultSubscription = Subscription(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Default Subscription',
          url:
              'https://raw.githubusercontent.com/cverhud/v2ray-sub/refs/heads/main/sub.txt',
          lastUpdated: DateTime.now(),
          configIds: [],
        );
        _subscriptions.add(defaultSubscription);
        await _v2rayService.saveSubscriptions(_subscriptions);
      }

      // Ensure configs are loaded and match subscription config IDs
      if (_configs.isEmpty) {
        _configs = await _v2rayService.loadConfigs();
      }

      // Verify that all subscription config IDs exist in the configs list
      // If not, it means the configs weren't properly saved or loaded
      for (var subscription in _subscriptions) {
        final configIds = subscription.configIds;
        final existingConfigIds = _configs.map((c) => c.id).toSet();

        // Check if any config IDs in the subscription are missing from the configs list
        final missingConfigIds = configIds
            .where((id) => !existingConfigIds.contains(id))
            .toList();

        if (missingConfigIds.isNotEmpty) {
          // Warning: Found missing configs for subscription
          // Update the subscription to remove missing config IDs
          final updatedConfigIds = configIds
              .where((id) => existingConfigIds.contains(id))
              .toList();
          final index = _subscriptions.indexWhere(
            (s) => s.id == subscription.id,
          );
          if (index != -1) {
            _subscriptions[index] = subscription.copyWith(
              configIds: updatedConfigIds,
            );
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load subscriptions: $e');
    } finally {
      _setLoading(false);
    }
    */ // END DISABLED CODE
  }

  Future<void> addConfig(V2RayConfig config) async {
    // Add config and display it immediately
    _configs.add(config);

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

  // Subscription management disabled
  Future<void> addSubscription(String name, String url) async {
    debugPrint('⚠️ addSubscription called but subscriptions are disabled');
    _setError('Subscription management is disabled. Only Smart/Plus servers are available.');
    return;
    /* DISABLED
    _setLoading(true);
    _errorMessage = '';
    try {
      final configs = await _v2rayService.parseSubscriptionUrl(url);
      if (configs.isEmpty) {
        _setError('No valid configurations found in subscription');
        return;
      }

      // Add configs and display them immediately
      _configs.addAll(configs);

      final newConfigIds = configs.map((c) => c.id).toList();

      // Create subscription
      final subscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        lastUpdated: DateTime.now(),
        configIds: newConfigIds,
      );

      _subscriptions.add(subscription);

      // Save both configs and subscription
      await _v2rayService.saveConfigs(_configs);
      await _v2rayService.saveSubscriptions(_subscriptions);

      // Update UI after everything is saved
      notifyListeners();
    } catch (e) {
      String errorMsg = 'Failed to add subscription';

      // Provide more specific error messages
      if (e.toString().contains('Network error') ||
          e.toString().contains('timeout') ||
          e.toString().contains('SocketException')) {
        errorMsg = 'Network error: Check your internet connection';
      } else if (e.toString().contains('Invalid URL')) {
        errorMsg = 'Invalid subscription URL format';
      } else if (e.toString().contains('No valid servers')) {
        errorMsg = 'No valid servers found in subscription';
      } else if (e.toString().contains('HTTP')) {
        errorMsg = 'Server error: ${e.toString()}';
      } else {
        errorMsg = 'Failed to add subscription: ${e.toString()}';
      }

      _setError(errorMsg);
    } finally {
      _setLoading(false);
    }
    */ // END DISABLED
  }

  // Subscription management disabled
  Future<void> updateSubscription(Subscription subscription) async {
    debugPrint('⚠️ updateSubscription called but subscriptions are disabled');
    _setError('Subscription management is disabled. Only Smart/Plus servers are available.');
    return;
    /* DISABLED
    // Original code commented out
    _setLoading(true);
    _isLoadingServers = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final configs = await _v2rayService.parseSubscriptionUrl(
        subscription.url,
      );
      if (configs.isEmpty) {
        _setError('No valid configurations found in subscription');
        _isLoadingServers = false;
        notifyListeners();
        return;
      }

      // Clear ping cache for old configs before removing them
      for (var configId in subscription.configIds) {
        _v2rayService.clearPingCache(configId: configId);
      }

      // Remove old configs
      _configs.removeWhere((c) => subscription.configIds.contains(c.id));

      // Add new configs and display them immediately
      _configs.addAll(configs);

      final newConfigIds = configs.map((c) => c.id).toList();

      // Update subscription
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription.copyWith(
          lastUpdated: DateTime.now(),
          configIds: newConfigIds,
        );

        // Save both configs and subscriptions to ensure persistence
        await _v2rayService.saveConfigs(_configs);
        await _v2rayService.saveSubscriptions(_subscriptions);
      }

      // Mark loading as complete
      _isLoadingServers = false;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      String errorMsg = 'Failed to update subscription';

      // Provide more specific error messages
      if (e.toString().contains('Network error') ||
          e.toString().contains('timeout') ||
          e.toString().contains('SocketException')) {
        errorMsg = 'Network error: Check your internet connection';
      } else if (e.toString().contains('Invalid URL')) {
        errorMsg = 'Invalid subscription URL format';
      } else if (e.toString().contains('No valid servers')) {
        errorMsg = 'No valid servers found in subscription';
      } else if (e.toString().contains('HTTP')) {
        errorMsg = 'Server error: ${e.toString()}';
      } else {
        errorMsg = 'Failed to update subscription: ${e.toString()}';
      }

      _setError(errorMsg);
    } finally {
      _setLoading(false);
    }
    */ // END DISABLED
  }

  // Subscription management disabled
  Future<void> updateSubscriptionInfo(Subscription subscription) async {
    debugPrint('⚠️ updateSubscriptionInfo called but subscriptions are disabled');
    return;
    /* DISABLED
    _setLoading(true);
    _errorMessage = '';

    try {
      // Find and update the subscription
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription;
        await _v2rayService.saveSubscriptions(_subscriptions);
        notifyListeners();
      } else {
        _setError('Subscription not found');
      }
    } catch (e) {
      String errorMsg = 'Failed to update subscription info';

      // Provide more specific error messages
      if (e.toString().contains('Network error') ||
          e.toString().contains('timeout') ||
          e.toString().contains('SocketException')) {
        errorMsg = 'Network error: Check your internet connection';
      } else if (e.toString().contains('Invalid URL')) {
        errorMsg = 'Invalid subscription URL format';
      } else if (e.toString().contains('Permission')) {
        errorMsg = 'Permission error: Unable to save subscription';
      } else {
        errorMsg = 'Failed to update subscription info: ${e.toString()}';
      }

      _setError(errorMsg);
    } finally {
      _setLoading(false);
    }
    */ // END DISABLED
  }

  // Update servers (replaces subscription update)
  // Now refreshes Smart/Plus servers instead of subscriptions
  Future<void> updateAllSubscriptions() async {
    _setLoading(true);
    _errorMessage = '';
    _isLoadingServers = true;
    notifyListeners();

    // Clear all ping cache before updating servers
    _v2rayService.clearPingCache();

    try {
      // Refresh servers from current source (Smart or Plus)
      await _fetchTiksarPlusServers(source: _serverSource);
      
      debugPrint('✅ ${serverSourceName} refreshed successfully');
      
      _isLoadingServers = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update all subscriptions: $e');
    } finally {
      _setLoading(false);
      _isLoadingServers = false;
    }
  }

  // Subscription management disabled
  Future<void> removeSubscription(Subscription subscription) async {
    debugPrint('⚠️ removeSubscription called but subscriptions are disabled');
    return;
    /* DISABLED
    // Remove configs associated with this subscription
    _configs.removeWhere((c) => subscription.configIds.contains(c.id));

    // Remove subscription
    _subscriptions.removeWhere((s) => s.id == subscription.id);

    await _v2rayService.saveConfigs(_configs);
    await _v2rayService.saveSubscriptions(_subscriptions);
    notifyListeners();
    */ // END DISABLED
  }

  Future<void> connectToServer(V2RayConfig config, bool isProxyMode) async {
    debugPrint('🚀 Starting connection to: ${config.remark}');
    
    // VALIDATION: Check if config is valid
    if (config.address.isEmpty || config.port <= 0) {
      _setError('Invalid server configuration: ${config.remark}');
      return;
    }
    
    // SAFETY: Prevent multiple simultaneous connections
    if (_isConnecting) {
      debugPrint('⚠️ Connection already in progress, ignoring duplicate request');
      return;
    }
    
    _isConnecting = true;
    _errorMessage = '';
    notifyListeners();

    // Connection configuration
    const int maxAttempts = 3;
    const int retryDelaySeconds = 1;
    const int connectionTimeout = 30;
    
    // Track connection success for finally block
    bool success = false;
    String lastError = '';

    try {
      debugPrint('📋 Connection parameters:');
      debugPrint('   - Server: ${config.remark}');
      debugPrint('   - Address: ${config.address}:${config.port}');
      debugPrint('   - Protocol: ${config.configType}');
      debugPrint('   - Proxy mode: $isProxyMode');
      debugPrint('   - Max attempts: $maxAttempts');
      
      // STEP 1: Disconnect from current server if connected
      if (_v2rayService.activeConfig != null) {
        debugPrint('🔌 Disconnecting from current server: ${_v2rayService.activeConfig?.remark}');
        try {
          await _v2rayService.disconnect()
              .timeout(const Duration(seconds: 5));
          debugPrint('✅ Disconnected from previous server');
          
          // Small delay to ensure clean disconnect
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('⚠️ Error disconnecting from current server: $e');
          // Continue with connection attempt even if disconnect failed
        }
      }

      // STEP 2: Try to connect with automatic retry
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        debugPrint('🔄 Connection attempt $attempt/$maxAttempts...');
        
        try {
          // Attempt connection with timeout
          success = await _v2rayService
              .connect(config, isProxyMode)
              .timeout(
                Duration(seconds: connectionTimeout),
                onTimeout: () {
                  debugPrint('⏱️ Connection timeout after ${connectionTimeout}s');
                  return false;
                },
              );

          if (success) {
            debugPrint('🎉 Connection attempt $attempt succeeded!');
            break;
          } else {
            lastError = 'Failed to connect to ${config.remark} on attempt $attempt';
            debugPrint('❌ $lastError');

            // If this is not the last attempt, wait before retrying
            if (attempt < maxAttempts) {
              debugPrint('⏳ Waiting ${retryDelaySeconds}s before retry...');
              await Future.delayed(Duration(seconds: retryDelaySeconds));
            }
          }
        } catch (e) {
          // Handle different types of errors
          if (e.toString().contains('timeout')) {
            lastError = 'Connection timeout on attempt $attempt';
            debugPrint('⏱️ $lastError: $e');
          } else if (e.toString().contains('permission')) {
            lastError = 'VPN permission denied';
            debugPrint('🚫 $lastError: $e');
            // Don't retry on permission errors
            break;
          } else {
            lastError = 'Error on connection attempt $attempt';
            debugPrint('❌ $lastError: $e');
          }

          // If this is not the last attempt, wait before retrying
          if (attempt < maxAttempts && !e.toString().contains('permission')) {
            debugPrint('⏳ Waiting ${retryDelaySeconds}s before retry...');
            await Future.delayed(Duration(seconds: retryDelaySeconds));
          }
        }
      }

      // STEP 3: Handle connection result
      if (success) {
        try {
          debugPrint('✅ VPN connection successful, updating UI state...');
          
          // CRITICAL PHASE 1: Establish grace period FIRST
          // This MUST be the very first thing to prevent race conditions
          _lastSuccessfulConnection = DateTime.now();
          debugPrint('🛡️ Grace period activated for 8 seconds');
          debugPrint('🛡️ Start time: ${_lastSuccessfulConnection!.toIso8601String()}');
          
          // CRITICAL PHASE 2: Update internal state IMMEDIATELY
          _errorMessage = '';
          
          // Update all configs: only connected one should be marked
          bool configUpdated = false;
          for (int i = 0; i < _configs.length; i++) {
            if (_configs[i].id == config.id) {
              _configs[i].isConnected = true;
              configUpdated = true;
              debugPrint('✅ Marked ${_configs[i].remark} as connected');
            } else if (_configs[i].isConnected) {
              _configs[i].isConnected = false;
              debugPrint('📴 Unmarked ${_configs[i].remark}');
            }
          }
          
          if (!configUpdated) {
            debugPrint('⚠️ Warning: Config ${config.id} not found in list, adding it');
            config.isConnected = true;
            _configs.add(config);
          }
          
          _selectedConfig = config;
          debugPrint('✅ Selected config updated: ${config.remark}');
          
          // CRITICAL PHASE 3: Verify activeConfig from service
          if (_v2rayService.activeConfig == null) {
            debugPrint('⚠️ WARNING: activeConfig is null after connection!');
            debugPrint('⚠️ This should not happen - connection may be unstable');
          } else {
            final activeRemark = _v2rayService.activeConfig?.remark ?? 'Unknown';
            debugPrint('✅ Service activeConfig verified: $activeRemark');
            
            // Double-check it matches our config
            if (_v2rayService.activeConfig?.id != config.id) {
              debugPrint('⚠️ Warning: activeConfig mismatch!');
              debugPrint('   Expected: ${config.id}');
              debugPrint('   Got: ${_v2rayService.activeConfig?.id}');
            }
          }
          
          // CRITICAL PHASE 4: Notify UI IMMEDIATELY
          notifyListeners();
          debugPrint('✅ UI notified - Connected: true, Error: cleared');
          
          // PHASE 5: Small delay to ensure UI renders
          await Future.delayed(const Duration(milliseconds: 150));
          
          // PHASE 6: Background tasks (non-blocking)
          debugPrint('📝 Starting background tasks...');
          
          _v2rayService.saveConfigs(_configs).catchError((e) {
            debugPrint('⚠️ Error saving configs: $e');
          });

          _v2rayService.resetUsageStats().catchError((e) {
            debugPrint('⚠️ Error resetting stats: $e');
          });
          
          _analyticsService.logVpnConnect(
            serverName: config.remark,
            serverAddress: config.address,
            serverPort: config.port,
            country: config.remark.split('-').first.trim(),
            protocol: config.configType,
          ).catchError((e) {
            debugPrint('⚠️ Analytics error: $e');
          });
          
          debugPrint('🎉 Connection fully established to ${config.remark}!');
          
        } catch (e) {
          debugPrint('❌ CRITICAL: Error in post-connection setup: $e');
          debugPrint('❌ Stack trace: ${StackTrace.current}');
          // Don't set error - connection succeeded, just setup failed
          // Still notify UI to show connected state
          notifyListeners();
        }
      } else {
        // Connection failed after all attempts
        debugPrint('💔 Connection failed after $maxAttempts attempts');
        debugPrint('💔 Last error: $lastError');
        _setError(
          'Failed to connect to ${config.remark} after $maxAttempts attempts: $lastError',
        );
      }
    } catch (e) {
      // Unexpected error in connection process
      debugPrint('❌ FATAL: Unexpected error in connection process');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      _setError('Unexpected error connecting to ${config.remark}: $e');
    } finally {
      debugPrint('🏁 Entering finally block...');
      debugPrint('🏁 Success: $success');
      debugPrint('🏁 _isConnecting: $_isConnecting');
      
      _isConnecting = false;
      
      // CRITICAL SAFETY CHECK: Verify connection state integrity
      if (success && _v2rayService.activeConfig != null) {
        debugPrint('🔍 Final state verification...');
        
        // Find the config that should be connected
        V2RayConfig? connectedConfig;
        try {
          connectedConfig = _configs.firstWhere(
            (c) => c.id == config.id,
            orElse: () {
              debugPrint('⚠️ Config not found in list, using provided config');
              return config;
            },
          );
        } catch (e) {
          debugPrint('❌ Error finding config: $e');
          connectedConfig = config;
        }
        
        // Verify and restore if needed
        if (!connectedConfig.isConnected) {
          debugPrint('🚨 CRITICAL: Connected state was corrupted! Restoring...');
          debugPrint('   Config: ${connectedConfig.remark}');
          debugPrint('   Should be connected: true');
          debugPrint('   Current state: ${connectedConfig.isConnected}');
          
          // Restore the correct state
          connectedConfig.isConnected = true;
          for (var c in _configs) {
            if (c.id != config.id && c.isConnected) {
              debugPrint('   Disconnecting: ${c.remark}');
              c.isConnected = false;
            }
          }
          
          debugPrint('✅ State restored successfully');
        } else {
          debugPrint('✅ State integrity verified - all good!');
        }
        
        // Final verification
        final activeRemark = _v2rayService.activeConfig?.remark ?? 'Unknown';
        final connectedCount = _configs.where((c) => c.isConnected).length;
        debugPrint('📊 Final state summary:');
        debugPrint('   Active config: $activeRemark');
        debugPrint('   Connected configs count: $connectedCount');
        debugPrint('   Selected config: ${_selectedConfig?.remark ?? 'None'}');
        
        if (connectedCount != 1) {
          debugPrint('⚠️ WARNING: Expected 1 connected config, got $connectedCount');
        }
      } else if (success && _v2rayService.activeConfig == null) {
        debugPrint('🚨 WARNING: Success but no activeConfig!');
        debugPrint('   This indicates a serious problem');
      }
      
      // Always notify UI at the end to ensure latest state
      notifyListeners();
      debugPrint('🏁 Connection process completed - UI notified');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
      
      // Update config status
      for (int i = 0; i < _configs.length; i++) {
        _configs[i].isConnected = false;
      }

      // After disconnect, always reset to first server
      if (_configs.isNotEmpty) {
        _selectedConfig = _configs.first;
        debugPrint('✅ Reset to first server after disconnect: ${_selectedConfig?.remark}');
      }

      // Persist the changes
      await _v2rayService.saveConfigs(_configs);
    } catch (e) {
      _setError('Error disconnecting: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Removed testServerDelay method as requested

  // Removed pingServer and pingAllServers methods as requested

  Future<void> selectConfig(V2RayConfig config) async {
    _selectedConfig = config;
    // Note: We don't save selected server anymore - always defaults to first server
    // User selection is temporary until disconnect
    
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
  }

  // تغییر وضعیت بین حالت پروکسی و تونل
  void toggleProxyMode(bool isProxy) {
    _isProxyMode = isProxy;
    // اینجا می‌توانیم منطق اضافی برای تغییر حالت اضافه کنیم
    // مثلاً ارسال دستور به سرویس برای تغییر حالت
    notifyListeners();
  }

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
    debugPrint('🔔 Notification disconnect triggered');
    
    // Actually disconnect the VPN service
    await _v2rayService.disconnect();
    
    // Update config status when disconnected from notification
    for (int i = 0; i < _configs.length; i++) {
      _configs[i].isConnected = false;
    }

    // IMPORTANT: Keep _selectedConfig so user can easily reconnect
    // Don't set _selectedConfig = null
    debugPrint('💾 Keeping selected config: ${_selectedConfig?.remark}');

    // Notify listeners immediately to update UI in real-time
    notifyListeners();

    // Persist the changes
    try {
      await _v2rayService.saveConfigs(_configs);
      notifyListeners();
      debugPrint('✅ Configs saved after notification disconnect');
    } catch (e) {
      debugPrint('❌ Error saving configs after notification disconnect: $e');
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed, checking VPN status immediately...');
      
      // CRITICAL: Like defyxVPN, check status IMMEDIATELY without delays
      // This ensures UI is synced with actual VPN state right away
      _syncVpnStatusOnResume();
      
    } else if (state == AppLifecycleState.paused) {
      // App is paused, VPN status will be maintained in background
      debugPrint('📱 App paused, VPN will continue in background');
    } else if (state == AppLifecycleState.inactive) {
      debugPrint('📱 App inactive');
    } else if (state == AppLifecycleState.detached) {
      debugPrint('📱 App detached');
    }
  }
  
  /// Sync VPN status immediately on app resume (inspired by defyxVPN)
  Future<void> _syncVpnStatusOnResume() async {
    if (_isInitializing || _isConnecting) {
      debugPrint('⏭️ Skipping sync - app is initializing or connecting');
      return;
    }
    
    try {
      debugPrint('🔄 Syncing VPN status on app resume...');
      
      // Check actual VPN connection status from native side
      final isActuallyConnected = await _v2rayService.isActuallyConnected()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ Status check timeout, using last known state');
              return _v2rayService.activeConfig != null;
            },
          );
      
      debugPrint('🔎 VPN actually connected: $isActuallyConnected');
      debugPrint('🔎 Active config: ${_v2rayService.activeConfig?.remark ?? "none"}');
      
      bool stateChanged = false;
      
      if (isActuallyConnected) {
        // VPN is running - ensure UI shows connected state
        final activeConfig = _v2rayService.activeConfig;
        if (activeConfig != null) {
          // Find and mark the connected config
          for (var config in _configs) {
            if (config.id == activeConfig.id || 
                (config.address == activeConfig.address && config.port == activeConfig.port)) {
              if (!config.isConnected) {
                config.isConnected = true;
                stateChanged = true;
              }
              _selectedConfig = config;
            } else if (config.isConnected) {
              config.isConnected = false;
              stateChanged = true;
            }
          }
          
          // Clear any error messages
          if (_errorMessage.isNotEmpty) {
            _errorMessage = '';
            stateChanged = true;
          }
          
          debugPrint('✅ VPN is connected to: ${activeConfig.remark}');
        }
      } else {
        // VPN is not running - ensure UI shows disconnected state
        for (var config in _configs) {
          if (config.isConnected) {
            config.isConnected = false;
            stateChanged = true;
          }
        }
        debugPrint('❌ VPN is disconnected');
      }
      
      // Save state if changed
      if (stateChanged) {
        await _v2rayService.saveConfigs(_configs);
        debugPrint('💾 Saved updated connection state');
      }
      
      // CRITICAL: Always notify UI to refresh
      notifyListeners();
      debugPrint('✅ UI notified of VPN state on resume');
      
    } catch (e) {
      debugPrint('❌ Error syncing VPN status on resume: $e');
      // Still notify to show last known state
      notifyListeners();
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


  // OPTIMISTIC UI: Load saved state immediately for instant UI display
  Future<void> _loadSavedStateAndShowUI() async {
    try {
      debugPrint('📂 Loading saved state for optimistic UI...');
      
      // Load configs from storage immediately (very fast, no network)
      final savedConfigs = await _v2rayService.loadConfigs();
      if (savedConfigs.isNotEmpty) {
        _configs = savedConfigs;
        debugPrint('📂 Loaded ${_configs.length} saved configs');
        
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
              debugPrint('📂 Restored selected server: ${_selectedConfig?.remark}');
            } else {
              debugPrint('⚠️ Saved server not found in configs');
            }
          } catch (e) {
            debugPrint('⚠️ Could not restore saved server: $e');
          }
        }
        
        // Check if any config is marked as connected
        final connectedConfigIndex = _configs.indexWhere((c) => c.isConnected);
        if (connectedConfigIndex != -1) {
          _selectedConfig = _configs[connectedConfigIndex];
          debugPrint('📂 Found connected config: ${_selectedConfig?.remark}');
        }
        
        // Notify UI immediately with saved state
        notifyListeners();
        debugPrint('✅ Optimistic UI loaded and displayed');
      } else {
        debugPrint('📂 No saved configs found');
      }
    } catch (e) {
      debugPrint('❌ Error loading saved state: $e');
      // Error loading saved state, continue with empty list
    }
  }

  /// Force check VPN status (inspired by defyxVPN's getVPNStatus)
  /// This method directly queries the VPN service for actual status
  /// Use this after app resume or when you need to verify connection state
  Future<void> forceCheckVpnStatus() async {
    try {
      debugPrint('🔎 Force checking VPN status from service...');
      
      // Get actual connection status from service with timeout
      final isActuallyConnected = await _v2rayService.isActuallyConnected()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⚠️ VPN status check timeout, assuming last known state');
              return _v2rayService.activeConfig != null;
            },
          );
      
      debugPrint('🔎 VPN actually connected: $isActuallyConnected');
      debugPrint('🔎 Active config: ${_v2rayService.activeConfig?.remark ?? "none"}');
      
      if (isActuallyConnected) {
        // VPN is running, sync state
        await _enhancedSyncWithVpnServiceState();
        
        // Clear any error messages when VPN is actually connected
        if (_errorMessage.isNotEmpty) {
          _errorMessage = '';
          debugPrint('✅ Cleared error message (VPN is connected)');
        }
        
        // CRITICAL: Ensure UI shows connected state
        final connectedConfig = _configs.firstWhere(
          (c) => c.isConnected,
          orElse: () => _configs.first,
        );
        
        debugPrint('✅ VPN status confirmed: CONNECTED');
        debugPrint('✅ Active server: ${_v2rayService.activeConfig?.remark ?? "Unknown"}');
        debugPrint('✅ UI showing: ${connectedConfig.remark} as connected');
      } else {
        // VPN is not running, clear all connection states
        bool stateChanged = false;
        for (var config in _configs) {
          if (config.isConnected) {
            config.isConnected = false;
            stateChanged = true;
          }
        }
        
        if (stateChanged) {
          await _v2rayService.saveConfigs(_configs);
          debugPrint('✅ VPN status confirmed: DISCONNECTED');
          debugPrint('✅ All configs marked as disconnected');
        } else {
          debugPrint('ℹ️ VPN already disconnected, no state change needed');
        }
      }
      
      // CRITICAL: Always notify UI to refresh, even if state didn't change
      // This ensures UI reflects the correct state after app resume
      notifyListeners();
      debugPrint('✅ UI notified of current VPN state');
    } catch (e) {
      debugPrint('❌ Error force checking VPN status: $e');
      // Still notify listeners to show last known state
      notifyListeners();
    }
  }
  
  // Method to manually check connection status
  Future<void> checkConnectionStatus() async {
    try {
      debugPrint('🔍 Checking connection status...');
      
      // Always check the actual VPN connection status
      final isActuallyConnected = await _v2rayService.isActuallyConnected();
      final activeConfig = _v2rayService.activeConfig;
      
      debugPrint('🔍 VPN is actually connected: $isActuallyConnected');
      debugPrint('🔍 Active config: ${activeConfig?.remark}');
      
      bool statusChanged = false;
      
      if (isActuallyConnected && activeConfig != null) {
        // VPN is actually connected - ensure UI shows this
        debugPrint('✅ VPN is connected, syncing UI...');
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
              debugPrint('✅ Found matching config: ${_configs[i].remark}');
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
            debugPrint('⚠️ Active config not in list, adding it');
            activeConfig.isConnected = true;
            _configs.insert(0, activeConfig);
            _selectedConfig = activeConfig;
            statusChanged = true;
          }
        }
      } else {
        // VPN is NOT connected - ensure all configs show disconnected
        debugPrint('❌ VPN is not connected, clearing all connection states');
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
        debugPrint('💾 Connection status saved');
      }
      
      // Always notify to refresh UI
      notifyListeners();
      debugPrint('🔄 UI updated with connection status');
    } catch (e) {
      debugPrint('❌ Error checking connection status: $e');
      // Don't change connection state on errors, but still notify UI
      notifyListeners();
    }
  }

  // ============================================================================
  // TIKSAR PLUS METHODS
  // Automatic server selection (similar to DXcore)
  // ============================================================================

  /// Change server source (Tiksar Smart or Tiksar Plus)
  /// 
  /// [source] - Server source: 'smart' or 'plus'
  /// 
  /// This will save the selection and reload servers
  Future<void> changeServerSource(String source) async {
    try {
      if (source != TiksarPlusService.sourceSmart && 
          source != TiksarPlusService.sourcePlus) {
        throw Exception('Invalid server source: $source');
      }
      
      debugPrint('🔄 Changing server source to: $source');
      
      _serverSource = source;
      
      // Save setting to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_source', source);
      
      // If auto mode is enabled, reload servers with new source
      if (_isAutoMode) {
        await _fetchTiksarPlusServers(source: source);
        debugPrint('✅ Server source changed to ${serverSourceName}');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error changing server source: $e');
      _setError('Failed to change server source: $e');
    }
  }

  /// Toggle Auto Mode is removed - Auto mode is always enabled
  /// Users can only switch between Tiksar Smart and Tiksar Plus

  /// Internal method to fetch servers from selected source (hidden from users)
  Future<void> _fetchTiksarPlusServers({String? source}) async {
    try {
      final selectedSource = source ?? _serverSource;
      final sourceName = selectedSource == TiksarPlusService.sourceSmart 
          ? 'Tiksar Smart' 
          : 'Tiksar Plus';
      debugPrint('📡 Fetching $sourceName servers...');
      
      // Fetch auto servers from selected source
      final autoServers = await _tiksarPlusService.fetchAutoServers(
        source: selectedSource,
      );

      if (autoServers.isNotEmpty) {
        debugPrint('✅ Fetched ${autoServers.length} Tiksar Plus servers');

        // Remove old auto servers
        _configs.removeWhere((c) => c.serverSource == 'auto');

        // Add new auto servers
        _configs.addAll(autoServers);

        // Save configs
        await _v2rayService.saveConfigs(_configs);

        debugPrint('✅ Tiksar Plus servers loaded');
      } else {
        debugPrint('⚠️ No Tiksar Plus servers found');
      }
    } catch (e) {
      debugPrint('❌ Error fetching Tiksar Plus servers: $e');
      throw e;
    }
  }

  /// Internal method to remove all auto servers
  Future<void> _removeAllAutoServers() async {
    try {
      debugPrint('🗑️ Removing all auto servers...');
      
      // Remove all auto servers
      _configs.removeWhere((c) => c.serverSource == 'auto');
      
      // If selected config was an auto server, clear selection
      if (_selectedConfig?.serverSource == 'auto') {
        _selectedConfig = null;
      }

      // Save updated configs
      await _v2rayService.saveConfigs(_configs);
      
      debugPrint('✅ Auto servers removed');
    } catch (e) {
      debugPrint('❌ Error removing auto servers: $e');
    }
  }
  
}
