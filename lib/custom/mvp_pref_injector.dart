import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MVP 产品 - SharedPreferences 本地 Key 预注入工具
class MvpPrefInjector {
  /// 在存储层预注入默认 App 设置（免责声明与数据收集声明标为已接受）
  static Future<void> ensurePreinjected([WidgetRef? ref]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configStr = prefs.getString('config');

      Map<String, dynamic> configMap = {};
      if (configStr != null && configStr.isNotEmpty) {
        try {
          configMap = json.decode(configStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      final appSettingProps =
          (configMap['appSettingProps'] as Map<String, dynamic>?) ?? {};
      final disclaimerAccepted = appSettingProps['disclaimerAccepted'] == true;
      final crashlyticsTip = appSettingProps['crashlyticsTip'] == true;

      // 若存储层未标记同意，注入标志位并写回 SharedPreferences
      if (!disclaimerAccepted || !crashlyticsTip) {
        appSettingProps['disclaimerAccepted'] = true;
        appSettingProps['crashlyticsTip'] = true;
        configMap['appSettingProps'] = appSettingProps;

        await prefs.setString('config', json.encode(configMap));
      }

      // 如果当前上下文有 Riverpod ref，同步刷新内存中的 State
      if (ref != null) {
        final currentSetting = ref.read(appSettingProvider);
        if (!currentSetting.disclaimerAccepted ||
            !currentSetting.crashlyticsTip) {
          ref.read(appSettingProvider.notifier).update(
                (state) => state.copyWith(
                  disclaimerAccepted: true,
                  crashlyticsTip: true,
                ),
              );
        }
      }
    } catch (e) {
      commonPrint.log('MvpPrefInjector error: $e', logLevel: LogLevel.warning);
    }
  }
}
