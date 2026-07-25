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
        // 1. Title 改成 Mi Mi
        title: const Text(
          'Mi Mi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // 2. Mode Switch (Light / Pro)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    isLightMode ? 'Light' : 'Pro',
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

              // 3. 核心大电源按钮区域 (去除重复多余的切换控件，精简为状态 Badge + 核心电源大按键)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: isStart
                        ? [
                            colorScheme.primaryContainer,
                            colorScheme.primaryContainer.withOpacity(0.6),
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
                          ? colorScheme.primary.withOpacity(0.25)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 状态 Badge (已连接 / 连接中... / 未连接)
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
                    const SizedBox(height: 32),

                    // 核心大电源 Icon 按键 (一键开启/停止连接)
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(customProxyStartProvider.notifier)
                            .setStart(!isStart);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isStart
                              ? colorScheme.primary
                              : colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: isStart
                                  ? colorScheme.primary.withOpacity(0.45)
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: isStart ? 30 : 16,
                              spreadRadius: isStart ? 6 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.power_settings_new_rounded,
                          size: 60,
                          color: isStart
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 提示说明文字
                    Text(
                      isStart ? '点击停止连接' : '点击启动连接',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isStart
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // 4. 配置文件卡片 (固定 135px 高度，平滑切换，绝对防抖动，去掉“专用”)
              Container(
                width: double.infinity,
                height: 135, // 绝对固定容器高度
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
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

                    // 内容平滑切换区
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
                                    height: 36,
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
