import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_models.dart';

class MvpAppBridge {
  static bool? watchIsStart(WidgetRef ref) {
    try {
      return ref.watch(isStartProvider);
    } catch (e) {
      commonPrint.log('watchIsStart error: $e', logLevel: LogLevel.warning);
      return null;
    }
  }

  static MvpCoreStatus? watchCoreStatus(WidgetRef ref) {
    try {
      final realCoreStatus = ref.watch(coreStatusProvider);
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
