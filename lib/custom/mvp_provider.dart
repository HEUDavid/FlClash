import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mvp_models.dart';

// MVP 模式开关 Provider
class CustomMvpNotifier extends Notifier<bool> {
  static const String _prefKey = 'custom_mvp_light_mode';

  @override
  bool build() {
    _init();
    return true;
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefKey);
      if (saved != null) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, state);
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, state);
    } catch (_) {}
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

  void toggle() {
    state = !state;
  }

  void setStart(bool value) {
    state = value;
  }
}

final customProxyStartProvider =
    NotifierProvider<CustomProxyStartNotifier, bool>(CustomProxyStartNotifier.new);

// 代理连接状态 Provider
final customCoreStatusProvider = Provider<MvpCoreStatus>((ref) {
  final isStart = ref.watch(customProxyStartProvider);
  return isStart ? MvpCoreStatus.connected : MvpCoreStatus.disconnected;
});

// 订阅配置列表 Provider
class CustomProfilesNotifier extends Notifier<List<MvpProfileItem>> {
  @override
  List<MvpProfileItem> build() {
    return const [
      MvpProfileItem(
        id: '1',
        label: '专线极速配置 v1.0',
        url: 'https://example.com/subscribe/node-a',
      ),
    ];
  }

  void addProfile(String url) {
    final label = '优化配置 ${state.length + 1}';
    final newItem = MvpProfileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      url: url,
    );
    state = [...state, newItem];
  }

  void addProfileFromBackup(String url) {
    final label = '远程备份数据 (${DateTime.now().month}/${DateTime.now().day})';
    final newItem = MvpProfileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      url: url,
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

  void selectId(String? id) {
    state = id;
  }
}

final customCurrentProfileIdProvider =
    NotifierProvider<CustomCurrentProfileIdNotifier, String?>(
        CustomCurrentProfileIdNotifier.new);
