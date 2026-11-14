import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mvp_hwid.dart';
import 'mvp_models.dart';

enum MvpVersionMatchType {
  regex,
  prefix,
  exact;

  static MvpVersionMatchType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'regex' => MvpVersionMatchType.regex,
      'prefix' => MvpVersionMatchType.prefix,
      _ => MvpVersionMatchType.exact,
    };
  }
}

enum MvpVersionActionType {
  openUrl,
  updateSubscription;

  static MvpVersionActionType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'update_subscription' => MvpVersionActionType.updateSubscription,
      _ => MvpVersionActionType.openUrl,
    };
  }
}

class MvpVersionRule {
  final String id;
  final MvpVersionMatchType matchType;
  final String pattern;
  final String title;
  final String message;
  final String actionButtonText;
  final String? targetUrl;
  final MvpVersionActionType actionType;

  const MvpVersionRule({
    required this.id,
    required this.matchType,
    required this.pattern,
    required this.title,
    required this.message,
    required this.actionButtonText,
    this.targetUrl,
    this.actionType = MvpVersionActionType.openUrl,
  });

  bool matches(String cleanVersion) {
    return switch (matchType) {
      MvpVersionMatchType.exact => cleanVersion == pattern,
      MvpVersionMatchType.prefix => cleanVersion.startsWith(pattern),
      MvpVersionMatchType.regex => RegExp(pattern).hasMatch(cleanVersion),
    };
  }

  factory MvpVersionRule.fromJson(Map<String, dynamic> json) {
    return MvpVersionRule(
      id: json['id'] as String? ?? '',
      matchType: MvpVersionMatchType.fromString(json['match_type'] as String?),
      pattern: json['pattern'] as String? ?? '',
      title: json['title'] as String? ?? '提示',
      message: json['message'] as String? ?? '',
      actionButtonText: json['action_button_text'] as String? ?? '确定',
      targetUrl: json['target_url'] as String?,
      actionType:
          MvpVersionActionType.fromString(json['action_type'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'match_type': matchType.name,
        'pattern': pattern,
        'title': title,
        'message': message,
        'action_button_text': actionButtonText,
        'target_url': targetUrl,
        'action_type': actionType.name,
      };
}

enum MvpVersionCheckStatus {
  ready,
  loading,
  incompleteRules,
  intercepted,
}

class MvpVersionCheckResult {
  final MvpVersionCheckStatus status;
  final MvpVersionRule? matchedRule;
  final String cleanVersion;

  const MvpVersionCheckResult._({
    required this.status,
    this.matchedRule,
    this.cleanVersion = '',
  });

  factory MvpVersionCheckResult.ready(String version) =>
      MvpVersionCheckResult._(
        status: MvpVersionCheckStatus.ready,
        cleanVersion: version,
      );

  factory MvpVersionCheckResult.loading() =>
      const MvpVersionCheckResult._(status: MvpVersionCheckStatus.loading);

  factory MvpVersionCheckResult.incomplete(String version) =>
      MvpVersionCheckResult._(
        status: MvpVersionCheckStatus.incompleteRules,
        cleanVersion: version,
      );

  factory MvpVersionCheckResult.intercept(
    MvpVersionRule rule,
    String version,
  ) =>
      MvpVersionCheckResult._(
        status: MvpVersionCheckStatus.intercepted,
        matchedRule: rule,
        cleanVersion: version,
      );
}

class MvpVersionConfigManager {
  static const String _storageKey = 'custom_mvp_version_config';
  static const String _lastSyncTimeKey = 'custom_mvp_version_config_last_sync';
  static const String _apiBaseUrlKey = 'custom_mvp_api_base_url';
  static const Duration _syncCooldown = Duration(minutes: 10);
  static const String remoteConfigEndpoint = '/fk/v-cfg';

  static String? _cachedApiBaseUrl;
  static List<MvpVersionRule>? _memoryCache;

  static const List<MvpVersionRule> defaultRules = [
    MvpVersionRule(
      id: 'outdated_client',
      matchType: MvpVersionMatchType.regex,
      pattern: r'^1(\.0)*$',
      title: '客户端版本过低',
      message: '当前版本过低，请访问官网获取最新版。如已下载安装最新App，请点击「同步」后重试。',
      actionButtonText: '前往下载',
      targetUrl: 'https://www.mdavid.cn/download',
      actionType: MvpVersionActionType.openUrl,
    ),
    MvpVersionRule(
      id: 'expired_subscription',
      matchType: MvpVersionMatchType.regex,
      pattern: r'^1\.9(\..+)?$',
      title: '防护已失效',
      message: '广告防护与隐私保护已失效，请获取最新配置链接并导入。',
      actionButtonText: '前往获取',
      targetUrl: 'https://www.mdavid.cn/download',
      actionType: MvpVersionActionType.updateSubscription,
    ),
  ];

  static List<MvpVersionRule> get activeRules => _memoryCache ?? defaultRules;

  static String? extractBaseUrl(String url) {
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        final portPart = uri.hasPort ? ':${uri.port}' : '';
        return '${uri.scheme}://${uri.host}$portPart';
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveApiBaseUrlFromUrl(String url) async {
    final base = extractBaseUrl(url);
    if (base != null && base.isNotEmpty && base != _cachedApiBaseUrl) {
      _cachedApiBaseUrl = base;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_apiBaseUrlKey, base);
      } catch (_) {}
    }
  }

  static Future<String?> getRemoteConfigUrl([String? url]) async {
    if (url != null && url.isNotEmpty) {
      final base = extractBaseUrl(url);
      if (base != null) {
        await saveApiBaseUrlFromUrl(url);
        return '$base$remoteConfigEndpoint';
      }
    }

    if (_cachedApiBaseUrl != null && _cachedApiBaseUrl!.isNotEmpty) {
      return '$_cachedApiBaseUrl$remoteConfigEndpoint';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_apiBaseUrlKey);
      if (stored != null && stored.isNotEmpty) {
        _cachedApiBaseUrl = stored;
        return '$stored$remoteConfigEndpoint';
      }
    } catch (_) {}

    return null;
  }

  static Future<void> init([String? fallbackUrl]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedApiBaseUrl = prefs.getString(_apiBaseUrlKey);
      if ((_cachedApiBaseUrl == null || _cachedApiBaseUrl!.isEmpty) &&
          fallbackUrl != null &&
          fallbackUrl.isNotEmpty) {
        await saveApiBaseUrlFromUrl(fallbackUrl);
      }

      final cachedJson = prefs.getString(_storageKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = json.decode(cachedJson);
        if (decoded is List) {
          _memoryCache = decoded
              .whereType<Map<String, dynamic>>()
              .map(MvpVersionRule.fromJson)
              .toList();
        }
      }
    } catch (_) {
      _memoryCache = defaultRules;
    }
  }

  static Future<void> syncFromRemoteIfNeeded([String? configUrl]) async {
    try {
      final remoteUrl = await getRemoteConfigUrl(configUrl);
      if (remoteUrl == null || remoteUrl.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSyncMs = prefs.getInt(_lastSyncTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (configUrl == null &&
          (now - lastSyncMs < _syncCooldown.inMilliseconds)) {
        return;
      }

      final hwid = await MvpHwid.getHwid();
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'X-HWID': hwid,
            'x-client-ver': '1.1',
          },
        ),
      );

      final response = await dio.get<dynamic>(remoteUrl);
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is String
            ? json.decode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final data = body['data'] ?? body;
        final rulesRaw = data is Map<String, dynamic> ? data['rules'] : null;
        if (rulesRaw is List) {
          final rulesList = rulesRaw
              .whereType<Map<String, dynamic>>()
              .map(MvpVersionRule.fromJson)
              .toList();
          if (rulesList.isNotEmpty) {
            _memoryCache = rulesList;
            await prefs.setString(
              _storageKey,
              json.encode(rulesList.map((e) => e.toJson()).toList()),
            );
            await prefs.setInt(_lastSyncTimeKey, now);
          }
        }
      }
    } catch (_) {}
  }

  static String cleanVersion(String raw) {
    var v = raw.trim();
    if (v.startsWith('版本：')) {
      v = v.substring(3).trim();
    }
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1).trim();
    }
    return v;
  }

  static MvpVersionRule? findMatchingRule(String cleanedVersion) {
    for (final rule in activeRules) {
      if (rule.matches(cleanedVersion)) {
        return rule;
      }
    }
    return null;
  }
}

String computeMvpRuleCountStr(MvpProfileItem profile) {
  final rulesCount = profile.rulesCount;
  final counts = profile.ruleProvidersCounts;

  if (rulesCount == null) {
    if (counts != null && counts.isNotEmpty) {
      return '版本：v${counts.join('.')}';
    }
    final totalRules = profile.ruleProvidersTotalRules;
    if (totalRules != null && totalRules > 0) {
      return '版本：v$totalRules';
    }
    return '版本获取中...';
  }

  if (counts != null && counts.isNotEmpty) {
    return '版本：v$rulesCount.${counts.join('.')}';
  }
  return '版本：v$rulesCount';
}

class MvpVersionChecker {
  static MvpVersionCheckResult check(String rawVersionText) {
    if (rawVersionText.isEmpty || rawVersionText.contains('版本获取中')) {
      return MvpVersionCheckResult.loading();
    }

    final cleaned = MvpVersionConfigManager.cleanVersion(rawVersionText);

    final matchedRule = MvpVersionConfigManager.findMatchingRule(cleaned);
    if (matchedRule != null) {
      return MvpVersionCheckResult.intercept(matchedRule, cleaned);
    }

    final parts = cleaned.split('.');
    final hasZeroSegment = parts.any((p) {
      final num = int.tryParse(p.trim());
      return num != null && num == 0;
    });

    if (hasZeroSegment) {
      return MvpVersionCheckResult.incomplete(cleaned);
    }

    return MvpVersionCheckResult.ready(cleaned);
  }
}
