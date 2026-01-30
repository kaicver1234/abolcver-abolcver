import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_update_info.dart';

class UpdateCheckerService {
  static const String _baseUrl = 
      'https://tiksarvpn-update.pages.dev/tiksar-vpn.json';

  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      // چک آپدیت در background با compute
      final result = await compute(_fetchUpdateInfo, _baseUrl);
      
      if (result != null && result.isNewerThan(currentVersion)) {
        return result;
      }
    } catch (_) {}

    return null;
  }

  // این تابع در isolate جداگانه اجرا میشه
  static Future<AppUpdateInfo?> _fetchUpdateInfo(String baseUrl) async {
    try {
      final url = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return AppUpdateInfo.fromJson(json);
      }
    } catch (_) {}

    return null;
  }
}
