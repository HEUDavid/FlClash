import 'package:dio/dio.dart';
import 'package:fl_clash/common/path.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';

// 桌面/移动原生端：真实的 backup.zip 下载与数据库 Restore 数据恢复 pipeline
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
