import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mvp_models.dart';

// MVP 模式开关 Provider
class CustomMvpNotifier extends StateNotifier<bool> {
  static const String _prefKey = 'custom_mvp_light_mode';

  CustomMvpNotifier() : super(true) {
    _init();
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
    StateNotifierProvider<CustomMvpNotifier, bool>((ref) {
  return CustomMvpNotifier();
});

// 代理启动/停止状态 Provider
class CustomProxyStartNotifier extends StateNotifier<bool> {
  CustomProxyStartNotifier() : super(false);

  void toggle() {
    state = !state;
  }

  void setStart(bool value) {
    state = value;
  }
}

final customProxyStartProvider =
    StateNotifierProvider<CustomProxyStartNotifier, bool>((ref) {
  return CustomProxyStartNotifier();
});

// 代理连接状态 Provider
final customCoreStatusProvider = Provider<MvpCoreStatus>((ref) {
  final isStart = ref.watch(customProxyStartProvider);
  return isStart ? MvpCoreStatus.connected : MvpCoreStatus.disconnected;
});

// 订阅配置列表 Provider
class CustomProfilesNotifier extends StateNotifier<List<MvpProfileItem>> {
  CustomProfilesNotifier()
      : super([
          const MvpProfileItem(
            id: '1',
            label: '默认高级订阅 A',
            url: 'https://example.com/subscribe/node-a',
          ),
          const MvpProfileItem(
            id: '2',
            label: '备用专线订阅 B',
            url: 'https://example.com/subscribe/node-b',
          ),
        ]);

  void addProfile(String url) {
    final label = '订阅配置 ${state.length + 1}';
    final newItem = MvpProfileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      url: url,
    );
    state = [...state, newItem];
  }
}

final customProfilesProvider =
    StateNotifierProvider<CustomProfilesNotifier, List<MvpProfileItem>>((ref) {
  return CustomProfilesNotifier();
});

// 当前选中的订阅配置 ID
final customCurrentProfileIdProvider = StateProvider<String?>((ref) {
  final profiles = ref.watch(customProfilesProvider);
  return profiles.isNotEmpty ? profiles.first.id : null;
});
