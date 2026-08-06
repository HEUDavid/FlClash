import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_models.dart';

// MVP 模式开关 Provider (默认每次启动都进入极简页面)
class CustomMvpNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  void setEnabled(bool value) {
    if (state == value) return;
    state = value;
  }
}

final customMvpProvider =
    NotifierProvider<CustomMvpNotifier, bool>(CustomMvpNotifier.new);

// 代理启动/停止状态 Provider
class CustomProxyStartNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setStart(bool value) {
    state = value;
  }
}

final customProxyStartProvider =
    NotifierProvider<CustomProxyStartNotifier, bool>(
        CustomProxyStartNotifier.new);

// 代理连接状态 Provider
final customCoreStatusProvider = Provider<MvpCoreStatus>((ref) {
  final isStart = ref.watch(customProxyStartProvider);
  return isStart ? MvpCoreStatus.connected : MvpCoreStatus.disconnected;
});

// 订阅配置列表 Provider
class CustomProfilesNotifier extends Notifier<List<MvpProfileItem>> {
  @override
  List<MvpProfileItem> build() {
    return const [];
  }

  void addProfileFromBackup(String url) {
    final label = '在线配置集 (${DateTime.now().month}/${DateTime.now().day})';
    final newItem = MvpProfileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      url: url,
      lastUpdateDate: DateTime.now(),
      rulesCount: 15,
      ruleProvidersCount: 3,
      ruleProvidersTotalRules: 45280,
      ruleProvidersCounts: const [9, 4, 13],
    );
    state = [...state, newItem];
  }
}

final customProfilesProvider =
    NotifierProvider<CustomProfilesNotifier, List<MvpProfileItem>>(
        CustomProfilesNotifier.new);

// 当前选中的订阅配置 ID
class CustomCurrentProfileIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final profiles = ref.watch(customProfilesProvider);
    return profiles.isNotEmpty ? profiles.first.id : null;
  }
}

final customCurrentProfileIdProvider =
    NotifierProvider<CustomCurrentProfileIdNotifier, String?>(
        CustomCurrentProfileIdNotifier.new);
