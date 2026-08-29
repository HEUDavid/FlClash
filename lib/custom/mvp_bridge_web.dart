import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_models.dart';

class _WebStartNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final _webStartProvider =
    NotifierProvider<_WebStartNotifier, bool>(_WebStartNotifier.new);

class _WebProfileNotifier extends Notifier<MvpProfileItem?> {
  @override
  MvpProfileItem? build() {
    final now = DateTime.now();
    return MvpProfileItem(
      id: 'web_preview_profile',
      label: '在线配置 (${now.month}/${now.day})',
      url: 'https://example.com/config.yaml',
      lastUpdateDate: now,
      rulesCount: 15,
      ruleProvidersCount: 3,
      ruleProvidersTotalRules: 45280,
      ruleProvidersCounts: const [9, 4, 13],
    );
  }

  void set(MvpProfileItem? value) => state = value;
}

final _webProfileProvider =
    NotifierProvider<_WebProfileNotifier, MvpProfileItem?>(
  _WebProfileNotifier.new,
);

class MvpBridge {
  static bool watchIsStart(WidgetRef ref) {
    return ref.watch(_webStartProvider);
  }

  static MvpCoreStatus watchCoreStatus(WidgetRef ref) {
    final isStart = ref.watch(_webStartProvider);
    return isStart ? MvpCoreStatus.connected : MvpCoreStatus.disconnected;
  }

  static MvpProfileItem? watchActiveProfile(WidgetRef ref) {
    return ref.watch(_webProfileProvider);
  }

  static void toggleShield(WidgetRef ref, bool currentIsStart) {
    ref.read(_webStartProvider.notifier).set(!currentIsStart);
  }

  static Future<bool> exportLogs(WidgetRef ref) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  static Future<void> importBackup(WidgetRef ref, String url) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    ref.read(_webProfileProvider.notifier).set(
          MvpProfileItem(
            id: now.millisecondsSinceEpoch.toString(),
            label: '在线配置 (${now.month}/${now.day})',
            url: url,
            lastUpdateDate: now,
            rulesCount: 15,
            ruleProvidersCount: 3,
            ruleProvidersTotalRules: 45280,
            ruleProvidersCounts: const [9, 4, 13],
          ),
        );
  }

  static Future<void> updateSubscription(WidgetRef ref, [String? url]) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final current = ref.read(_webProfileProvider);
    if (current != null) {
      ref.read(_webProfileProvider.notifier).set(
            current.copyWith(
              lastUpdateDate: DateTime.now(),
            ),
          );
    }
  }
}
