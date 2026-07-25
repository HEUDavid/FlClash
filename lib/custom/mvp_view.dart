import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_models.dart';
import 'mvp_provider.dart';

class CustomMvpView extends ConsumerStatefulWidget {
  const CustomMvpView({super.key});

  @override
  ConsumerState<CustomMvpView> createState() => _CustomMvpViewState();
}

class _CustomMvpViewState extends ConsumerState<CustomMvpView> {
  final TextEditingController _urlController = TextEditingController();
  bool _isImporting = false;
  bool _showInputArea = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!.trim();
      setState(() {});
    }
  }

  Future<void> _handleImportSubscription() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的订阅链接'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ref.read(customProfilesProvider.notifier).addProfile(url);
      _urlController.clear();
      setState(() {
        _isImporting = false;
        _showInputArea = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配置导入成功，已自动生效！'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLightMode = ref.watch(customMvpProvider);
    final isStart = ref.watch(customProxyStartProvider);
    final coreStatus = ref.watch(customCoreStatusProvider);
    final profiles = ref.watch(customProfilesProvider);
    final currentProfileId = ref.watch(customCurrentProfileIdProvider);

    // 获取当前唯一在用的优化配置
    final activeProfile = profiles.firstWhere(
      (element) => element.id == currentProfileId,
      orElse: () => profiles.isNotEmpty
          ? profiles.first
          : const MvpProfileItem(id: '', label: '', url: ''),
    );
    final hasProfile = activeProfile.id.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '极简加速器',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          // 模式切换 Segment/Chip (Light 极简 <-> 高级设置)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    isLightMode ? 'Light 极简' : '高级设置',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: isLightMode,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) {
                      ref.read(customMvpProvider.notifier).setEnabled(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 1. 核心大按钮与一键连接展示 Card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: isStart
                        ? [
                            colorScheme.primaryContainer,
                            colorScheme.primaryContainer.withOpacity(0.7),
                          ]
                        : [
                            colorScheme.surfaceContainerHigh,
                            colorScheme.surfaceContainer,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isStart
                          ? colorScheme.primary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 连接状态 Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isStart
                            ? Colors.green.withOpacity(0.15)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: switch (coreStatus) {
                                MvpCoreStatus.connected => Colors.green,
                                MvpCoreStatus.connecting => Colors.orange,
                                MvpCoreStatus.disconnected => Colors.grey,
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            switch (coreStatus) {
                              MvpCoreStatus.connected => '加速服务已连接',
                              MvpCoreStatus.connecting => '正在准备连接...',
                              MvpCoreStatus.disconnected => '未连接服务',
                            },
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isStart
                                  ? Colors.green.shade800
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 大电源启动/停止按钮 Icon
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(customProxyStartProvider.notifier)
                            .setStart(!isStart);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isStart
                              ? colorScheme.primary
                              : colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: isStart
                                  ? colorScheme.primary.withOpacity(0.4)
                                  : Colors.black12,
                              blurRadius: isStart ? 24 : 12,
                              spreadRadius: isStart ? 4 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.power_settings_new_rounded,
                          size: 56,
                          color: isStart
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 启动/停止连接按钮
                    SizedBox(
                      width: 180,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          ref
                              .read(customProxyStartProvider.notifier)
                              .setStart(!isStart);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: isStart
                              ? colorScheme.errorContainer
                              : colorScheme.primary,
                          foregroundColor: isStart
                              ? colorScheme.onErrorContainer
                              : colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          isStart ? '停止连接' : '启动连接',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // 2. 极简唯一配置文件与链接导入 Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '专用配置文件',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (hasProfile)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showInputArea = !_showInputArea;
                              });
                            },
                            child: Text(
                              _showInputArea ? '收起' : '更换链接',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 展示唯一极简配置或订阅输入框
                    if (hasProfile && !_showInputArea) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeProfile.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '优选线路配置 (已激活)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: '粘贴优化后的订阅链接...',
                          prefixIcon: const Icon(Icons.link, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste, size: 20),
                            tooltip: '粘贴',
                            onPressed: _handlePaste,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton.icon(
                          onPressed:
                              _isImporting ? null : _handleImportSubscription,
                          icon: _isImporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(_isImporting ? '导入配置中...' : '导入订阅配置'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
