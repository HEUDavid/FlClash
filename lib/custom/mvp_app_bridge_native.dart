import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_models.dart';
import 'mvp_pref_injector.dart';

class MvpAppBridge {
  static bool get isMockSupported => false;

  static void ensureInitSettings(WidgetRef ref) {
    MvpPrefInjector.ensurePreinjected(ref);
  }

  static bool? watchIsStart(WidgetRef ref) {
    try {
      final bool val = ref.watch(isStartProvider);
      return val;
    } catch (e) {
      commonPrint.log('watchIsStart error: $e', logLevel: LogLevel.warning);
      return null;
    }
  }

  static MvpCoreStatus? watchCoreStatus(WidgetRef ref) {
    try {
      final CoreStatus realCoreStatus = ref.watch(coreStatusProvider);
      return switch (realCoreStatus) {
        CoreStatus.connected => MvpCoreStatus.connected,
        CoreStatus.connecting => MvpCoreStatus.connecting,
        CoreStatus.disconnected => MvpCoreStatus.disconnected,
      };
    } catch (e) {
      commonPrint.log('watchCoreStatus error: $e', logLevel: LogLevel.warning);
      return null;
    }
  }

  static MvpProfileItem? watchActiveProfile(WidgetRef ref) {
    try {
      final loadedProviders = ref.watch(providersProvider);
      final ruleProviders =
          loadedProviders.where((item) => item.type == 'Rule').toList();
      final int? ruleProvidersTotalRules = ruleProviders.isNotEmpty
          ? ruleProviders.fold<int>(0, (sum, item) => sum + item.count)
          : null;
      final List<int>? ruleProvidersCounts = ruleProviders.isNotEmpty
          ? ruleProviders.map((item) => item.count).toList()
          : null;

      final realCurrentProfile = ref.watch(currentProfileProvider);
      if (realCurrentProfile != null) {
        final clashConfig =
            ref.watch(clashConfigProvider(realCurrentProfile.id)).value;
        return MvpProfileItem(
          id: realCurrentProfile.id.toString(),
          label: realCurrentProfile.label.isNotEmpty
              ? realCurrentProfile.label
              : '在线配置集合',
          url: realCurrentProfile.url,
          lastUpdateDate: realCurrentProfile.lastUpdateDate,
          rulesCount: clashConfig?.rules.length,
          ruleProvidersCount: clashConfig?.ruleProviders.length,
          ruleProvidersTotalRules: ruleProvidersTotalRules,
          ruleProvidersCounts: ruleProvidersCounts,
        );
      }
      final realProfiles = ref.watch(profilesProvider);
      if (realProfiles.isNotEmpty) {
        final p = realProfiles.first;
        final clashConfig = ref.watch(clashConfigProvider(p.id)).value;
        return MvpProfileItem(
          id: p.id.toString(),
          label: p.label.isNotEmpty ? p.label : '在线配置集合',
          url: p.url,
          lastUpdateDate: p.lastUpdateDate,
          rulesCount: clashConfig?.rules.length,
          ruleProvidersCount: clashConfig?.ruleProviders.length,
          ruleProvidersTotalRules: ruleProvidersTotalRules,
          ruleProvidersCounts: ruleProvidersCounts,
        );
      }
    } catch (e) {
      commonPrint.log('watchActiveProfile error: $e',
          logLevel: LogLevel.warning);
    }
    return null;
  }

  static void toggleShield(WidgetRef ref, bool currentIsStart) {
    try {
      final isInit = !ref.read(initProvider);
      ref.read(setupActionProvider.notifier).updateStatus(
            !currentIsStart,
            isInit: isInit,
          );
    } catch (e) {
      commonPrint.log('toggleShield error: $e', logLevel: LogLevel.warning);
    }
  }

  static Future<bool> exportLogs(WidgetRef ref) async {
    try {
      final res = await globalState.safeRun<bool>(() async {
        return ref.read(logsProvider.notifier).exportLogs();
      }, title: '导出日志');
      return res == true;
    } catch (e) {
      commonPrint.log('exportLogs error: $e', logLevel: LogLevel.warning);
      return false;
    }
  }
}
