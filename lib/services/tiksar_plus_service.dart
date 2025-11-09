import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/v2ray_config.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

/// Tiksar Server Service
/// 
/// This service provides automatic server selection with multiple sources:
/// - Tiksar Smart: Uses DXcore protocols (XRAY, OUTLINE, PSIPHON, WARP, SERVERLESS, GOOL)
/// - Tiksar Plus: Uses standard V2Ray protocols (vmess, vless, shadowsocks, trojan)
class TiksarPlusService {
  // Server source URLs
  // Note: Tiksar Smart uses native DXcore - servers are managed by DXcore library itself
  // We just enable/disable the DXcore functionality
  static const String smartServerUrl = 
      'AUTO_MANAGED_BY_DXCORE'; // DXcore manages its own servers
  
  static const String plusServerUrl = 
      'https://raw.githubusercontent.com/cverhud/v2ray-sub/refs/heads/main/sub.txt';
  
  // Server source types
  static const String sourceSmart = 'smart';
  static const String sourcePlus = 'plus';
  
  // Default source (Tiksar Smart)
  static const String defaultSource = sourceSmart;
  
  // DXcore protocol types
  static const List<String> dxcoreProtocols = [
    'XRAY',
    'OUTLINE', 
    'PSIPHON',
    'WARP',
    'SERVERLESS',
    'GOOL',
  ];

  /// Fetch servers for automatic mode based on selected source
  /// 
  /// [source] - Server source: 'smart' or 'plus'
  /// 
  /// Returns a list of V2RayConfig with serverSource set to 'auto'
  /// These servers are hidden from users and managed automatically
  Future<List<V2RayConfig>> fetchAutoServers({String? source}) async {
    try {
      final selectedSource = source ?? defaultSource;
      
      // If Tiksar Smart is selected, return placeholder
      // DXcore will handle actual connection with its native protocols
      if (selectedSource == sourceSmart) {
        return _createSmartPlaceholder();
      }
      
      // For Tiksar Plus, fetch servers from GitHub
      final url = plusServerUrl;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json, text/plain',
          'User-Agent': 'TiksarVPN/2.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<V2RayConfig> servers = [];
        
        // Try to parse as JSON first (flowLine format similar to DXcore)
        try {
          final dynamic jsonData = jsonDecode(response.body);
          
          // Check if it's a flowLine format (like DXcore)
          if (jsonData is Map && jsonData.containsKey('flowLine')) {
            servers.addAll(_parseFlowLineFormat(Map<String, dynamic>.from(jsonData)));
          } 
          // Check if it's a simple array of server configs
          else if (jsonData is List) {
            for (var item in jsonData) {
              if (item is Map) {
                final config = _parseServerConfig(Map<String, dynamic>.from(item));
                if (config != null) {
                  servers.add(config);
                }
              }
            }
          }
          // Check if it's a single server config
          else if (jsonData is Map) {
            final config = _parseServerConfig(Map<String, dynamic>.from(jsonData));
            if (config != null) {
              servers.add(config);
            }
          }
        } catch (e) {
          // If JSON parsing fails, try to parse as plain text with V2Ray URIs
          servers.addAll(_parsePlainText(response.body));
        }

        return servers;
      } else {
        throw Exception('Failed to load Tiksar Plus servers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Tiksar Plus servers: $e');
    }
  }

  /// Parse flowLine format (DXcore compatible)
  List<V2RayConfig> _parseFlowLineFormat(Map<String, dynamic> flowLineData) {
    final List<V2RayConfig> servers = [];
    
    try {
      final flowLineStr = flowLineData['flowLine'];
      if (flowLineStr is String) {
        // Try to parse flowLine as JSON
        try {
          final flowLineJson = jsonDecode(flowLineStr);
          if (flowLineJson is List) {
            for (var item in flowLineJson) {
              if (item is Map<String, dynamic>) {
                final config = _parseServerConfig(item);
                if (config != null) {
                  servers.add(config);
                }
              }
            }
          }
        } catch (e) {
          // If flowLine is not JSON, try to parse as plain text
          servers.addAll(_parsePlainText(flowLineStr));
        }
      } else if (flowLineStr is List) {
        for (var item in flowLineStr) {
          if (item is Map<String, dynamic>) {
            final config = _parseServerConfig(item);
            if (config != null) {
              servers.add(config);
            }
          }
        }
      }
    } catch (e) {
      // Error parsing flowLine
    }

    return servers;
  }

  /// Parse server configuration
  V2RayConfig? _parseServerConfig(Map<String, dynamic> json) {
    try {
      // Check for different possible key names
      final String remark = json['remark'] ?? 
                           json['ps'] ?? 
                           json['name'] ?? 
                           json['label'] ?? 
                           'Tiksar Plus Server';
      
      final String address = json['address'] ?? 
                            json['add'] ?? 
                            json['server'] ?? 
                            json['host'] ?? 
                            '';
      
      final int port = int.tryParse(json['port']?.toString() ?? '') ?? 
                       int.tryParse(json['serverPort']?.toString() ?? '') ?? 
                       443;
      
      final String configType = json['type'] ?? 
                               json['protocol'] ?? 
                               json['net'] ?? 
                               'vmess';

      if (address.isEmpty) {
        return null;
      }

      return V2RayConfig(
        id: 'auto_${json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()}',
        remark: '⚡ $remark', // Add Tiksar Plus indicator
        address: address,
        port: port,
        configType: configType,
        fullConfig: jsonEncode(json),
        serverSource: 'auto', // Mark as automatic server
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse plain text format (V2Ray URIs)
  List<V2RayConfig> _parsePlainText(String text) {
    final List<V2RayConfig> servers = [];
    final lines = text.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if it's a V2Ray URI
      if (line.contains('://')) {
        final config = _parseUriConfig(line);
        if (config != null) {
          servers.add(config);
        }
      }
    }

    return servers;
  }

  /// Parse V2Ray URI configuration
  V2RayConfig? _parseUriConfig(String uri) {
    try {
      if (uri.startsWith('vmess://') ||
          uri.startsWith('vless://') ||
          uri.startsWith('ss://') ||
          uri.startsWith('trojan://')) {
        
        try {
          V2RayURL parser = FlutterV2ray.parseFromURL(uri);
          String configType = '';

          if (uri.startsWith('vmess://')) {
            configType = 'vmess';
          } else if (uri.startsWith('vless://')) {
            configType = 'vless';
          } else if (uri.startsWith('ss://')) {
            configType = 'shadowsocks';
          } else if (uri.startsWith('trojan://')) {
            configType = 'trojan';
          }

          return V2RayConfig(
            id: 'auto_${DateTime.now().millisecondsSinceEpoch.toString()}',
            remark: '⚡ ${parser.remark}', // Add Tiksar Plus indicator
            address: parser.address,
            port: parser.port,
            configType: configType,
            fullConfig: uri,
            serverSource: 'auto', // Mark as automatic server
          );
        } catch (e) {
          return null;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create placeholder for Tiksar Smart (DXcore)
  /// 
  /// Tiksar Smart uses DXcore which has multiple protocol types:
  /// XRAY, OUTLINE, PSIPHON, WARP, SERVERLESS, GOOL
  /// 
  /// These are managed by DXcore native library, not standard V2Ray
  /// We create placeholder configs to indicate Smart mode is active
  List<V2RayConfig> _createSmartPlaceholder() {
    return [
      V2RayConfig(
        id: 'smart_auto',
        remark: '🧠 Tiksar Smart (Auto)',
        address: 'auto.tiksar.network',
        port: 443,
        configType: 'dxcore', // Special type for DXcore
        fullConfig: jsonEncode({
          'type': 'dxcore',
          'protocols': dxcoreProtocols,
          'auto': true,
          'description': 'Tiksar Smart auto-managed protocols: ${dxcoreProtocols.join(", ")}'
        }),
        serverSource: 'auto',
      ),
    ];
  }

  /// Test connection to server URL
  /// Returns true if the URL is reachable
  Future<bool> testConnection({String? customUrl}) async {
    try {
      final url = customUrl ?? plusServerUrl;
      final response = await http.head(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200 || response.statusCode == 405;
    } catch (e) {
      return false;
    }
  }
}
