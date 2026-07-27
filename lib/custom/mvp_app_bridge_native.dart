import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_models.dart';
import 'mvp_pref_injector.dart';

class MvpAppBridge {
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
      final realCurrentProfile = ref.watch(currentProfileProvider);
      if (realCurrentProfile != null) {
        return MvpProfileItem(
          id: realCurrentProfile.id.toString(),
          label: realCurrentProfile.label.isNotEmpty
              ? realCurrentProfile.label
              : '在线配置集合',
          url: realCurrentProfile.url,
        );
      }
      final realProfiles = ref.watch(profilesProvider);
      if (realProfiles.isNotEmpty) {
        final p = realProfiles.first;
        return MvpProfileItem(
          id: p.id.toString(),
          label: p.label.isNotEmpty ? p.label : '在线配置集合',
          url: p.url,
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
}
