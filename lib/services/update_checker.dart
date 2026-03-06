import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;
}

class GitHubUpdateChecker {
  GitHubUpdateChecker({
    this.owner = 'NEOLEE98',
    this.repo = 'aemeath-pet-flutter',
  });

  final String owner;
  final String repo;

  String get releasesPageUrl => 'https://github.com/$owner/$repo/releases';

  Uri get _latestReleaseApiUri =>
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');

  Future<UpdateCheckResult?> checkForUpdates() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version.trim();

      final client = HttpClient();
      try {
        final request = await client
            .getUrl(_latestReleaseApiUri)
            .timeout(const Duration(seconds: 8));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set(HttpHeaders.userAgentHeader, 'aemeath-pet-app');

        final response =
            await request.close().timeout(const Duration(seconds: 8));
        if (response.statusCode != HttpStatus.ok) {
          return null;
        }

        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }

        final rawTag = (decoded['tag_name'] as String? ?? '').trim();
        if (rawTag.isEmpty) {
          return null;
        }

        final latestVersion = _normalizeVersion(rawTag);
        final releaseUrl =
            (decoded['html_url'] as String?)?.trim().isNotEmpty == true
                ? (decoded['html_url'] as String).trim()
                : releasesPageUrl;

        return UpdateCheckResult(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          releaseUrl: releaseUrl,
          hasUpdate: _compareSemver(latestVersion, currentVersion) > 0,
        );
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }

  String _normalizeVersion(String value) {
    var v = value.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    return v;
  }

  int _compareSemver(String a, String b) {
    final aCore = _extractCore(a);
    final bCore = _extractCore(b);
    final maxLen = aCore.length > bCore.length ? aCore.length : bCore.length;

    for (var i = 0; i < maxLen; i++) {
      final av = i < aCore.length ? aCore[i] : 0;
      final bv = i < bCore.length ? bCore[i] : 0;
      if (av != bv) {
        return av.compareTo(bv);
      }
    }

    return 0;
  }

  List<int> _extractCore(String version) {
    var v = _normalizeVersion(version);
    final plusIndex = v.indexOf('+');
    if (plusIndex >= 0) {
      v = v.substring(0, plusIndex);
    }
    final dashIndex = v.indexOf('-');
    if (dashIndex >= 0) {
      v = v.substring(0, dashIndex);
    }

    return v
        .split('.')
        .map((segment) =>
            int.tryParse(segment.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList(growable: false);
  }
}
