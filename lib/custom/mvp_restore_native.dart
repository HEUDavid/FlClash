import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      },
    ),
  );

  final response = await dio.download(downloadUrl, tempEncryptedPath);

  if (response.statusCode == 200) {
    final tempFile = File(tempEncryptedPath);
    try {
      // 预先检查 Header 中的文件名，判断是不是 fk 接口
      final contentDisposition = response.headers.value('content-disposition') ?? '';
      if (!contentDisposition.contains('fk-config.zip')) {
        throw '配置文件链接无效';
      }

      final zipDecoder = ZipDecoder();
      final bytes = await tempFile.readAsBytes();
      late final Archive archive;
      try {
        archive = zipDecoder.decodeBytes(bytes, password: 'BlockAd2026');
      } catch (e) {
        throw '配置文件格式错误';
      }

      final unencryptedBytes = ZipEncoder().encode(archive);
      await File(backupPath).writeAsBytes(unencryptedBytes);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    await globalState.container
        .read(backupActionProvider.notifier)
        .restore(RestoreOption.all);
    await _syncAndRefreshProviders(globalState.container);
  } else {
    throw '文件下载失败，服务器响应: ${response.statusCode}，请检查链接是否有效';
  }
}

// 原生端：触发更新订阅 URL 文件以及规则集（Rule Providers），并应用生效
Future<void> updateSubscriptionOrBackup(String url) async {
  final container = globalState.container;

  // 1. 刷新订阅 Profile 文件
  await container.read(profilesActionProvider.notifier).updateProfiles();

  // 2. 触发所有外部 Provider 的规则同步与核心配置应用
  await _syncAndRefreshProviders(container);
}

Future<void> _syncAndRefreshProviders(ProviderContainer container) async {
  // 1. 首次应用 Profile 配置，让内核绑定并解析出配置文件中的 Provider 列表
  await container.read(setupActionProvider.notifier).applyProfile(force: true);

  // 2. 同步 Provider 列表，确保 Riverpod 获取到内核中初始注册的 Providers
  await container.read(providersProvider.notifier).syncProviders();

  // 3. 遍历拉取并下载所有的规则集与外部 Provider (Rule / Proxy Providers)
  final providers = container.read(providersProvider);
  if (providers.isNotEmpty) {
    final updateTasks = (providers as Iterable).map<Future<void>>((provider) async {
      try {
        await container
            .read(proxiesActionProvider.notifier)
            .updateProvider(provider);
      } catch (e) {
        commonPrint.log('updateProvider fail, retrying: $e', logLevel: LogLevel.warning);
        await Future.delayed(const Duration(seconds: 1));
        try {
          await container
              .read(proxiesActionProvider.notifier)
              .updateProvider(provider);
        } catch (e2) {
          commonPrint.log('updateProvider error after retry: $e2', logLevel: LogLevel.warning);
        }
      }
    });
    await Future.wait(updateTasks);

    // 4. 所有外部文件下载完毕后，再次同步，获取真实的完整规则条数（不为0）
    await container.read(providersProvider.notifier).syncProviders();

    // 5. 再次应用配置，确保刚下载完的外部规则被内核安全加载，杜绝警告
    await container
        .read(setupActionProvider.notifier)
        .applyProfile(force: true);
  }

  // 6. 刷新并使当前的 clashConfig 缓存失效，保障 UI 立即反映正确的规则条数
  final currentProfileId = container.read(currentProfileIdProvider);
  if (currentProfileId != null) {
    container.invalidate(clashConfigProvider(currentProfileId));
  }
}
