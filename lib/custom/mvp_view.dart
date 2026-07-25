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

    // 获取当前配置文件 (如果存在)
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
        // 1. 标题改成 mimi
        title: const Text(
          'mimi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          // 2. Mode Switch (Light / Pro)
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
                    isLightMode ? 'Light' : 'Pro',
                    style: TextStyle(
                      fontSize: 13,
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

              // 3. 核心开关区域：已连接 / 未连接 开关展示
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                    // 连接状态 Tag (已连接 / 未连接)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
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
                              MvpCoreStatus.connected => '已连接',
                              MvpCoreStatus.connecting => '连接中...',
                              MvpCoreStatus.disconnected => '未连接',
                            },
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isStart
                                  ? Colors.green.shade800
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 大开关 Button Icon
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(customProxyStartProvider.notifier)
                            .setStart(!isStart);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 110,
                        height: 110,
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
                          size: 52,
                          color: isStart
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 已连接 / 未连接 开关控件
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isStart ? '已连接' : '未连接',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isStart
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Transform.scale(
                          scale: 1.1,
                          child: Switch(
                            value: isStart,
                            onChanged: (value) {
                              ref
                                  .read(customProxyStartProvider.notifier)
                                  .setStart(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // 4 & 5. 配置文件卡片与更换/收起（固定高度 140px 防止页面抖动，去掉“专用”）
              Container(
                width: double.infinity,
                height: 140, // 固定容器高度，解决展开/收起时的抖动问题
                padding: const EdgeInsets.all(16),
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
                              Icons.description_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            // 5. 去掉“专用”，改成“配置文件”
                            const Text(
                              '配置文件',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (hasProfile)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                _showInputArea = !_showInputArea;
                              });
                            },
                            child: Text(
                              _showInputArea ? '收起' : '更换',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 内容展示区（固定高度放下对应内容，不触发表格尺寸跳跃抖动）
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: (hasProfile && !_showInputArea)
                            ? Container(
                                key: const ValueKey('profile_card'),
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.task_alt_rounded,
                                      color: colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activeProfile.label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '优选线路配置 (已激活)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                key: const ValueKey('input_form'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _urlController,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: '粘贴订阅链接...',
                                        hintStyle:
                                            const TextStyle(fontSize: 12),
                                        prefixIcon: const Icon(Icons.link,
                                            size: 18),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.content_paste,
                                              size: 16),
                                          tooltip: '粘贴',
                                          onPressed: _handlePaste,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 34,
                                    child: FilledButton(
                                      onPressed: _isImporting
                                          ? null
                                          : _handleImportSubscription,
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        _isImporting ? '导入中...' : '导入配置',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
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
