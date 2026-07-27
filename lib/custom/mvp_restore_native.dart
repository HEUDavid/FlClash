import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';

import 'package:fl_clash/custom/mvp_hwid.dart';

// 桌面/移动原生端：下载远程 backup.zip 压缩包（支持 BlockAd2026 密码解压 + 设备 HWID 绑定）并恢复全量数据
Future<void> downloadAndRestoreBackup(String url) async {
  final hwid = await MvpHwid.getHwid();
  final uri = Uri.parse(url);
  final queryParams = Map<String, String>.from(uri.queryParameters);
  queryParams['hwid'] = hwid;
  final downloadUrl = uri.replace(queryParameters: queryParams).toString();

  final tempEncryptedPath = '${await appPath.backupFilePath}.download';
  final backupPath = await appPath.backupFilePath;
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      headers: {
        'X-HWID': hwid,
        'X-Device-ID': hwid,
      },
    ),
  );

  final response = await dio.download(downloadUrl, tempEncryptedPath);

  if (response.statusCode == 200) {
    final tempFile = File(tempEncryptedPath);
    try {
      final zipDecoder = ZipDecoder();
      final bytes = await tempFile.readAsBytes();
      late final Archive archive;
      try {
        archive = zipDecoder.decodeBytes(bytes, password: 'BlockAd2026');
      } catch (_) {
        archive = zipDecoder.decodeBytes(bytes);
      }

      final unencryptedBytes = ZipEncoder().encode(archive);

      if (unencryptedBytes != null) {
        await File(backupPath).writeAsBytes(unencryptedBytes);
      }
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    await globalState.container
        .read(backupActionProvider.notifier)
        .restore(RestoreOption.all);
    await globalState.container
        .read(setupActionProvider.notifier)
        .applyProfile(force: true);
  } else {
    throw 'HTTP ${response.statusCode}';
  }
}

// 原生端：触发更新订阅 URL 文件以及规则集（Rule Providers），并应用生效
Future<void> updateSubscriptionOrBackup(String url) async {
  final container = globalState.container;

  // 1. 刷新订阅 Profile 文件
  await container.read(profilesActionProvider.notifier).updateProfiles();

  // 2. 刷新所有规则集与外部 Provider (Rule / Proxy Providers)
  final providers = container.read(providersProvider);
  if (providers.isNotEmpty) {
    final updateTasks = providers.map((provider) async {
      try {
        await container
            .read(proxiesActionProvider.notifier)
            .updateProvider(provider);
      } catch (e) {
        commonPrint.log('updateProvider error: $e', logLevel: LogLevel.warning);
      }
    });
    await Future.wait(updateTasks);
  }

  // 3. 重新同步并载入核心配置
  await container.read(providersProvider.notifier).syncProviders();
  await container.read(setupActionProvider.notifier).applyProfile(force: true);
}
