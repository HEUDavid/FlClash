import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_provider.dart';
import 'mvp_view.dart';

class CustomMvp {
  /// 判断当前是否处于 Light MVP 模式
  static bool isLightMode(WidgetRef ref) {
    return ref.watch(customMvpProvider);
  }

  /// 切换 MVP / 原版模式
  static void toggleMode(WidgetRef ref) {
    ref.read(customMvpProvider.notifier).toggle();
  }

  /// 包装主页视图：如果启用 Light MVP 则展示 MVP UI，否则展示原版 UI
  static Widget buildHomeView({
    required Widget defaultView,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final isLight = ref.watch(customMvpProvider);
        if (isLight) {
          return const CustomMvpView();
        }
        return defaultView;
      },
    );
  }
}
