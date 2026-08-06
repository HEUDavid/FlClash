import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_models.dart';

class MvpAppBridge {
  static bool get isMockSupported => true;

  static bool? watchIsStart(WidgetRef ref) => null;

  static MvpCoreStatus? watchCoreStatus(WidgetRef ref) => null;

  static MvpProfileItem? watchActiveProfile(WidgetRef ref) => null;

  static void ensureInitSettings(WidgetRef ref) {}

  static void toggleShield(WidgetRef ref, bool currentIsStart) {}

  static Future<bool> exportLogs(WidgetRef ref) async {
    return false;
  }
}
