import 'dart:async';
import 'package:flutter/services.dart';

/// DXcore Service
/// 
/// Based on defyxVPN implementation
/// Interface for DXcore library which provides multiple protocols:
/// - XRAY, OUTLINE, PSIPHON, WARP, GOOL, SERVERLESS
/// 
/// DXcore automatically manages server selection and connection
class DXcoreService {
  static const MethodChannel _channel = MethodChannel('com.tiksarvpn.app/dxcore');
  static const EventChannel _eventChannel = EventChannel('com.tiksarvpn.app/dxcore_events');
  
  StreamSubscription? _eventSubscription;
  
  /// Stream of DXcore events (connection status, progress, etc.)
  Stream<Map<String, dynamic>> get vpnEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{'raw': event.toString()};
    });
  }
  
  /// Start VPN with DXcore
  /// 
  /// [flowLine] - Server configuration JSON (from DXcore)
  /// [pattern] - Pattern for server selection
  /// 
  /// Based on defyxVPN: startVPN(flowLine, pattern)
  Future<void> startVPN({required String flowLine, String pattern = ''}) async {
    try {
      await _channel.invokeMethod('startVPN', {
        'flowLine': flowLine,
        'pattern': pattern,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to start VPN: ${e.message}');
    }
  }
  
  /// Stop VPN completely
  Future<void> stopVPN() async {
    try {
      await _channel.invokeMethod('stopVPN');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop VPN: ${e.message}');
    }
  }
  
  /// Disconnect VPN (soft disconnect)
  Future<void> disconnectVpn() async {
    try {
      await _channel.invokeMethod('disconnectVpn');
    } on PlatformException catch (e) {
      throw Exception('Failed to disconnect: ${e.message}');
    }
  }
  
  /// Connect VPN (create tunnel)
  /// Returns true if permission granted and tunnel created
  Future<bool> connectVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>('connectVpn');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to connect: ${e.message}');
    }
  }
  
  /// Get current VPN status
  /// Returns: 'connected', 'disconnected', 'connecting', etc.
  Future<String> getVpnStatus() async {
    try {
      final result = await _channel.invokeMethod<String>('getVpnStatus');
      return result ?? 'disconnected';
    } on PlatformException catch (e) {
      throw Exception('Failed to get status: ${e.message}');
    }
  }
  
  /// Check if tunnel is running
  Future<bool> isTunnelRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTunnelRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      return false;
    }
  }
  
  /// Get FlowLine from DXcore
  /// FlowLine contains server configs and protocols
  Future<String> getFlowLine() async {
    try {
      final result = await _channel.invokeMethod<String>('getFlowLine');
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to get flowLine: ${e.message}');
    }
  }
  
  /// Request VPN permission from Android
  Future<bool> grantVpnPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('grantVpnPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to grant permission: ${e.message}');
    }
  }
  
  /// Check if DXcore library is available
  /// 
  /// Returns:
  /// - available: bool
  /// - version: String
  /// - protocols: List<String>
  Future<Map<String, dynamic>> isAvailable() async {
    try {
      final result = await _channel.invokeMethod('isAvailable');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      // If method channel fails, DXcore is not available
      return {
        'available': false,
        'version': null,
        'protocols': [],
        'error': e.message
      };
    }
  }
  
  /// Check if DXcore is currently connected
  Future<bool> isConnected() async {
    try {
      final status = await getVpnStatus();
      return status == 'connected';
    } catch (e) {
      return false;
    }
  }
  
  /// Listen to VPN events
  void listenToEvents(Function(Map<String, dynamic>) onEvent) {
    _eventSubscription?.cancel();
    _eventSubscription = vpnEvents.listen(onEvent);
  }
  
  /// Stop listening to events
  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
  
  /// Dispose service
  void dispose() {
    stopListening();
  }
}
