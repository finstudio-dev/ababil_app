import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Details about a newer release found on GitHub.
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String? notes;

  UpdateInfo({required this.version, required this.downloadUrl, this.notes});
}

/// Compares two dotted version strings (e.g. "1.2.0" vs "1.10.0"), ignoring
/// any leading "v". Returns true if [remote] is newer than [current].
bool _isNewer(String remote, String current) {
  List<int> parts(String s) =>
      s.replaceFirst(RegExp(r'^v'), '').split('.').map((p) => int.tryParse(p) ?? 0).toList();

  final r = parts(remote);
  final c = parts(current);
  final len = r.length > c.length ? r.length : c.length;

  for (var i = 0; i < len; i++) {
    final rv = i < r.length ? r[i] : 0;
    final cv = i < c.length ? c[i] : 0;
    if (rv != cv) return rv > cv;
  }
  return false;
}

/// Checks the GitHub repo in [AppConfig.githubRepo] for a release newer
/// than [AppConfig.appVersion]. Returns null if already up to date, if
/// there are no releases yet, or if the check fails for any reason
/// (offline, GitHub unreachable, no internet, etc.) — this is a nice-to-
/// have and must never throw or block the app from opening normally.
Future<UpdateInfo?> checkForUpdate() async {
  try {
    final res = await http
        .get(
          Uri.parse('https://api.github.com/repos/${AppConfig.githubRepo}/releases/latest'),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 6));

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = data['tag_name'] as String?;
    if (tag == null || !_isNewer(tag, AppConfig.appVersion)) return null;

    final assets = (data['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    Map<String, dynamic>? apkAsset;
    for (final a in assets) {
      if ((a['name'] as String? ?? '').toLowerCase().endsWith('.apk')) {
        apkAsset = a;
        break;
      }
    }

    final downloadUrl = apkAsset?['browser_download_url'] as String? ??
        data['html_url'] as String? ??
        'https://github.com/${AppConfig.githubRepo}/releases/latest';

    return UpdateInfo(version: tag, downloadUrl: downloadUrl, notes: data['body'] as String?);
  } catch (_) {
    return null;
  }
}
