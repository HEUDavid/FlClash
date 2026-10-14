import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MVP 产品 - SharedPreferences 本地 Key 预注入工具
class MvpPrefInjector {
  /// 在存储层预注入 MVP 设置（免责声明/统计收集标为已接受以跳过弹窗，自动更新设为关闭）
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
      // 避免首次启动弹窗：免责声明与统计收集提示
      final disclaimerAccepted = appSettingProps['disclaimerAccepted'] == true;
      final crashlyticsTip = appSettingProps['crashlyticsTip'] == true;
      // 避免检查上游版本：MVP 独立版始终强制关闭自动更新
      final needDisableAutoUpdate =
          appSettingProps['autoCheckUpdate'] != false;

      if (!disclaimerAccepted || !crashlyticsTip || needDisableAutoUpdate) {
        appSettingProps['disclaimerAccepted'] = true;
        appSettingProps['crashlyticsTip'] = true;
        appSettingProps['autoCheckUpdate'] = false;
        configMap['appSettingProps'] = appSettingProps;

        await prefs.setString('config', json.encode(configMap));
      }

      if (ref != null) {
        final currentSetting = ref.read(appSettingProvider);
        if (!currentSetting.disclaimerAccepted ||
            !currentSetting.crashlyticsTip ||
            currentSetting.autoCheckUpdate) {
          ref.read(appSettingProvider.notifier).update(
                (state) => state.copyWith(
                  disclaimerAccepted: true,
                  crashlyticsTip: true,
                  autoCheckUpdate: false,
                ),
              );
        }
      }
    } catch (e) {
      commonPrint.log('MvpPrefInjector error: $e', logLevel: LogLevel.warning);
    }
  }
}
