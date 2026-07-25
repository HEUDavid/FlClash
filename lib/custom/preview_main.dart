import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        // Mock 初始数据用于独立预览
        coreStatusProvider.overrideWith((ref) => CoreStatus.disconnected),
        isStartProvider.overrideWith((ref) => false),
        profilesProvider.overrideWith((ref) => [
              const Profile(
                id: '1',
                label: '示例节点订阅 A',
                url: 'https://example.com/subscribe/node-a',
                type: ProfileType.url,
              ),
              const Profile(
                id: '2',
                label: 'VIP 高速订阅 B',
                url: 'https://example.com/subscribe/node-b',
                type: ProfileType.url,
              ),
            ]),
      ],
      child: const MvpPreviewApp(),
    ),
  );
}

class MvpPreviewApp extends StatelessWidget {
  const MvpPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MVP UI 独立预览',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const CustomMvpView(),
    );
  }
}
