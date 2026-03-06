import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'update_checker.dart';

class DesktopUpdateNoticeStore {
  static const String _key = 'desktop_pending_update_notice_v1';

  static Future<void> save(UpdateCheckResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(<String, String>{
      'currentVersion': result.currentVersion,
      'latestVersion': result.latestVersion,
      'releaseUrl': result.releaseUrl,
    });
    await prefs.setString(_key, payload);
  }

  static Future<UpdateCheckResult?> peek() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final currentVersion =
          (decoded['currentVersion'] as String?)?.trim() ?? '';
      final latestVersion = (decoded['latestVersion'] as String?)?.trim() ?? '';
      final releaseUrl = (decoded['releaseUrl'] as String?)?.trim() ?? '';
      if (currentVersion.isEmpty ||
          latestVersion.isEmpty ||
          releaseUrl.isEmpty) {
        return null;
      }

      return UpdateCheckResult(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
        hasUpdate: true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
