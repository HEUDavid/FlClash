import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_hwid.dart';
import 'mvp_models.dart';

class MvpBridge {
  static bool watchIsStart(WidgetRef ref) {
    return ref.watch(isStartProvider);
  }

  static MvpCoreStatus watchCoreStatus(WidgetRef ref) {
    final CoreStatus realCoreStatus = ref.watch(coreStatusProvider);
    return switch (realCoreStatus) {
      CoreStatus.connected => MvpCoreStatus.connected,
      CoreStatus.connecting => MvpCoreStatus.connecting,
      CoreStatus.disconnected => MvpCoreStatus.disconnected,
    };
  }

  static MvpProfileItem? watchActiveProfile(WidgetRef ref) {
    final loadedProviders = ref.watch(providersProvider);
    final ruleProviders =
        loadedProviders.where((item) => item.type == 'Rule').toList();
    final int? ruleProvidersTotalRules = ruleProviders.isNotEmpty
        ? ruleProviders.fold<int>(0, (sum, item) => sum + item.count)
        : null;
    final List<int>? ruleProvidersCounts = ruleProviders.isNotEmpty
        ? ruleProviders.map((item) => item.count).toList()
        : null;

    final profile = ref.watch(currentProfileProvider) ??
        ref.watch(profilesProvider).firstOrNull;

    if (profile == null) {
      return null;
    }

    final clashConfig = ref.watch(clashConfigProvider(profile.id)).value;
    return MvpProfileItem(
      id: profile.id.toString(),
      label: profile.label.isNotEmpty ? profile.label : '在线配置集',
      url: profile.url,
      lastUpdateDate: profile.lastUpdateDate,
      rulesCount: clashConfig?.rules.length,
      ruleProvidersCount: clashConfig?.ruleProviders.length,
      ruleProvidersTotalRules: ruleProvidersTotalRules,
      ruleProvidersCounts: ruleProvidersCounts,
    );
  }

  static void toggleShield(WidgetRef ref, bool currentIsStart) {
    final running = !currentIsStart;
    ref.read(setupActionProvider.notifier).setRunning(
          running,
          initialize: running && !ref.read(initProvider),
        );
  }

  static Future<bool> exportLogs(WidgetRef ref) async {
    final res = await globalState.safeRun<bool>(
      () async => ref.read(logsProvider.notifier).exportLogs(),
      title: '导出日志',
    );
    return res == true;
  }

  static Future<void> importBackup(WidgetRef ref, String url) async {
    final hwid = await MvpHwid.getHwid();
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['hwid'] = hwid;
    final downloadUrl = uri.replace(queryParameters: queryParams).toString();

    final backupPath = await appPath.backupFilePath;
    final tempEncryptedPath = '$backupPath.download';
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

    if (response.statusCode != 200) {
      throw Exception('文件下载失败，服务器响应: ${response.statusCode}，请检查链接是否有效');
    }

    final tempFile = File(tempEncryptedPath);
    try {
      final contentDisposition =
          response.headers.value('content-disposition') ?? '';
      if (!contentDisposition.contains('fk-config.zip')) {
        throw Exception('配置文件链接无效');
      }

      final zipDecoder = ZipDecoder();
      final bytes = await tempFile.readAsBytes();
      late final Archive archive;
      try {
        archive = zipDecoder.decodeBytes(bytes, password: 'BlockAd2026');
      } catch (_) {
        throw Exception('配置文件格式错误');
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
  }

  static Future<void> updateSubscription(WidgetRef ref, [String? url]) async {
    final container = globalState.container;
    await container.read(profilesActionProvider.notifier).updateProfiles();
    await _syncAndRefreshProviders(container);
  }

  static Future<void> _syncAndRefreshProviders(
    ProviderContainer container,
  ) async {
    await container
        .read(setupActionProvider.notifier)
        .applyProfile(force: true);
    await container.read(providersProvider.notifier).syncProviders();

    final providers = container.read(providersProvider);
    if (providers.isNotEmpty) {
      final updateTasks = providers.map<Future<void>>((provider) async {
        try {
          final message = await container
              .read(proxiesActionProvider.notifier)
              .updateProvider(provider);
          if (message.isNotEmpty) {
            await Future.delayed(const Duration(seconds: 1));
            await container
                .read(proxiesActionProvider.notifier)
                .updateProvider(provider);
          }
        } catch (_) {}
      });
      await Future.wait(updateTasks);

      await container.read(providersProvider.notifier).syncProviders();
      await container
          .read(setupActionProvider.notifier)
          .applyProfile(force: true);
    }

    final currentProfileId = container.read(currentProfileIdProvider);
    if (currentProfileId != null) {
      container.invalidate(clashConfigProvider(currentProfileId));
    }
  }
}
