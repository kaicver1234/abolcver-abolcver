import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

class WindowsProxyService {
  static const int INTERNET_OPTION_REFRESH = 37;
  static const int INTERNET_OPTION_SETTINGS_CHANGED = 39;
  static const int INTERNET_OPTION_PROXY = 38;

  static bool _isProxyEnabled = false;
  static String? _previousProxySettings;

  static bool get isProxyEnabled => _isProxyEnabled;

  static Future<bool> enableSystemProxy({
    required String host,
    required int port,
  }) async {
    if (!Platform.isWindows) {
      debugPrint('⚠️ Proxy configuration is only supported on Windows');
      return false;
    }

    try {
      debugPrint('🔧 Enabling Windows system proxy: $host:$port');

      final result = await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f'
      ]);

      if (result.exitCode != 0) {
        debugPrint('❌ Failed to enable proxy: ${result.stderr}');
        return false;
      }

      final serverResult = await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        '$host:$port',
        '/f'
      ]);

      if (serverResult.exitCode != 0) {
        debugPrint('❌ Failed to set proxy server: ${serverResult.stderr}');
        return false;
      }

      final bypassResult = await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyOverride',
        '/t',
        'REG_SZ',
        '/d',
        'localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*;<local>',
        '/f'
      ]);

      if (bypassResult.exitCode != 0) {
        debugPrint('⚠️ Warning: Failed to set proxy bypass list');
      }

      await _notifyProxyChange();

      _isProxyEnabled = true;
      debugPrint('✅ Windows system proxy enabled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling system proxy: $e');
      return false;
    }
  }

  static Future<bool> disableSystemProxy() async {
    if (!Platform.isWindows) {
      debugPrint('⚠️ Proxy configuration is only supported on Windows');
      return false;
    }

    try {
      debugPrint('🔧 Disabling Windows system proxy');

      final result = await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f'
      ]);

      if (result.exitCode != 0) {
        debugPrint('❌ Failed to disable proxy: ${result.stderr}');
        return false;
      }

      await _notifyProxyChange();

      _isProxyEnabled = false;
      debugPrint('✅ Windows system proxy disabled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling system proxy: $e');
      return false;
    }
  }

  static Future<void> _notifyProxyChange() async {
    try {
      await Process.run('netsh', ['winhttp', 'import', 'proxy', 'source=ie']);
      
      final ipconfigResult = await Process.run('ipconfig', ['/flushdns']);
      if (ipconfigResult.exitCode == 0) {
        debugPrint('✅ DNS cache flushed');
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Failed to notify proxy change: $e');
    }
  }

  static Future<Map<String, dynamic>> getProxyStatus() async {
    if (!Platform.isWindows) {
      return {'enabled': false, 'server': null};
    }

    try {
      final enableResult = await Process.run('reg', [
        'query',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable'
      ]);

      final serverResult = await Process.run('reg', [
        'query',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyServer'
      ]);

      final enabledMatch =
          RegExp(r'ProxyEnable\s+REG_DWORD\s+0x(\d+)').firstMatch(
        enableResult.stdout.toString(),
      );

      final serverMatch =
          RegExp(r'ProxyServer\s+REG_SZ\s+(.+)').firstMatch(
        serverResult.stdout.toString(),
      );

      final enabled = enabledMatch != null && enabledMatch.group(1) == '1';
      final server = serverMatch?.group(1)?.trim();

      return {'enabled': enabled, 'server': server};
    } catch (e) {
      debugPrint('⚠️ Error getting proxy status: $e');
      return {'enabled': false, 'server': null};
    }
  }

  static Future<void> restorePreviousProxy() async {
    if (_previousProxySettings != null) {
      debugPrint('🔄 Restoring previous proxy settings');
      await disableSystemProxy();
      _previousProxySettings = null;
    }
  }
}
