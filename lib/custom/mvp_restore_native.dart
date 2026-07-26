import 'package:dio/dio.dart';
import 'package:fl_clash/common/path.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';

// 桌面/移动原生端：下载远程 backup.zip 压缩包并恢复全量数据
Future<void> downloadAndRestoreBackup(String url) async {
  final backupPath = await appPath.backupFilePath;
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
    ),
  );

  final response = await dio.download(url, backupPath);

  if (response.statusCode == 200) {
    await globalState.container
        .read((backupActionProvider as dynamic).notifier)
        .restore(RestoreOption.all);
  } else {
    throw 'HTTP ${response.statusCode}';
  }
}

// 原生端：仅触发更新订阅 URL 文件及其包含的规则（无需重新拉取 backup.zip 全量备份）
Future<void> updateSubscriptionOrBackup(String url) async {
  await globalState.container
      .read((profilesActionProvider as dynamic).notifier)
      .updateProfiles();
}
