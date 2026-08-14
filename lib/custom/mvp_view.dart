import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_app_bridge_helper.dart';
import 'mvp_models.dart';
import 'mvp_provider.dart';
import 'mvp_restore_helper.dart';

/// MvpTheme defines the clean, light design system colors and styling tokens
/// strictly matching the iOS CustomMvp implementation.
abstract final class MvpTheme {
  // Backgrounds & Surface Card Colors
  static const bgPrimary = Color(0xFFF8FAFC); // #F8FAFC
  static const cardBg = Color(0xFFFFFFFF); // #FFFFFF
  static const borderColor = Color(0xFFE2E8F0); // #E2E8F0

  // Primary Active & Accent Colors (Emerald Green #10B981)
  static const activeColor = Color(0xFF10B981); // #10B981

  // Inactive & Disabled Colors
  static const inactiveGray = Color(0xFFD1D5DB); // #D1D5DB
  static const inactiveBadgeBg = Color(0xFFE5E7EB); // #E5E7EB

  // Additional UI Colors
  static const dangerColor = Color(0xFFEF4444); // #EF4444
  static const dangerText = Color(0xFFF87171); // #F87171 (soft red)
  static const inputBg = Color(0xFFF9FAFB); // #F9FAFB

  // Typography Colors
  static const textPrimary = Color(0xFF0F172A); // #0F172A
  static const textSecondary = Color(0xFF64748B); // #64748B

  // Toast & Warning Colors
  static const toastBg = Color(0xFF1E293B); // #1E293B
}

class CustomMvpView extends ConsumerStatefulWidget {
  const CustomMvpView({super.key});

  @override
  ConsumerState<CustomMvpView> createState() => _CustomMvpViewState();
}

class _CustomMvpViewState extends ConsumerState<CustomMvpView> {
  final TextEditingController _urlController = TextEditingController();
  bool _isImporting = false;
  bool _isUpdating = false;
  bool _isExportingLogs = false;
  bool _showInputArea = false;
  bool _isConnectionToggling = false;

  int _minimalTapCount = 0;
  DateTime? _lastMinimalTapTime;

  @override
  void initState() {
    super.initState();
    MvpAppBridge.ensureInitSettings(ref);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showMvpToast(
    String message, {
    MvpToastType type = MvpToastType.info,
    Duration duration = const Duration(seconds: 2),
    String? copyData,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              switch (type) {
                MvpToastType.info => Icons.info_rounded,
                MvpToastType.success => Icons.check_circle_rounded,
                MvpToastType.error => Icons.error_rounded,
                MvpToastType.warning => Icons.warning_amber_rounded,
              },
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: MvpTheme.toastBg,
        duration: duration,
        action: copyData != null
            ? SnackBarAction(
                label: '复制',
                textColor: Colors.white,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: copyData));
                },
              )
            : null,
      ),
    );
  }

  void _handleMinimalTap() {
    final now = DateTime.now();
    if (_lastMinimalTapTime != null &&
        now.difference(_lastMinimalTapTime!) > const Duration(seconds: 2)) {
      _minimalTapCount = 0;
    }
    _lastMinimalTapTime = now;
    _minimalTapCount++;

    if (_minimalTapCount >= 5) {
      _minimalTapCount = 0;
      ref.read(customMvpProvider.notifier).setEnabled(false);
      _showMvpToast('已切换至高级模式', type: MvpToastType.info);
    }
  }

  Future<void> _handleExportLogs() async {
    if (_isExportingLogs) return;
    setState(() {
      _isExportingLogs = true;
    });

    try {
      final res = await MvpAppBridge.exportLogs(ref);
      if (res == true && mounted) {
        _showMvpToast('日志导出成功', type: MvpToastType.success);
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) {
        setState(() {
          _isExportingLogs = false;
        });
      }
    }
  }

  void _handleToggleShield(bool currentIsStart, bool hasProfile) {
    if (_isConnectionToggling || _isUpdating || _isImporting) {
      if (_isUpdating || _isImporting) {
        _showMvpToast('操作处理中，请稍候...', type: MvpToastType.warning);
      }
      return;
    }

    if (!hasProfile) {
      setState(() {
        _showInputArea = true;
      });
      _showMvpToast('请先导入配置文件', type: MvpToastType.info);
      return;
    }

    _isConnectionToggling = true;

    MvpAppBridge.toggleShield(ref, currentIsStart);
    ref.read(customProxyStartProvider.notifier).setStart(!currentIsStart);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isConnectionToggling = false;
        });
      }
    });
  }

  Future<void> _handleUpdateSubscription(String url) async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
    });

    try {
      await updateSubscriptionOrBackup(url);
      if (!mounted) return;
      _showMvpToast('已同步至最新', type: MvpToastType.success);
    } catch (e) {
      if (!mounted) return;
      _showMvpToast(
        '更新失败: $e',
        type: MvpToastType.error,
        copyData: '更新失败: $e',
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _urlController.text = text.trim();
      setState(() {});
    }
  }

  Future<void> _handleImportConfigZip() async {
    final url = _urlController.text.trim();
    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      _showMvpToast('请输入有效的配置文件链接', type: MvpToastType.info);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isImporting = true;
    });

    try {
      await downloadAndRestoreBackup(url);
      if (!mounted) return;

      if (MvpAppBridge.isMockSupported) {
        ref.read(customProfilesProvider.notifier).addProfileFromBackup(url);
      }
      _urlController.clear();

      setState(() {
        _showInputArea = false;
      });
      _showMvpToast('导入成功', type: MvpToastType.success);
    } catch (e) {
      if (!mounted) return;
      _showMvpToast(
        '导入失败: $e',
        type: MvpToastType.error,
        copyData: '导入失败: $e',
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isStart = MvpAppBridge.watchIsStart(ref) ??
        (MvpAppBridge.isMockSupported
            ? ref.watch(customProxyStartProvider)
            : false);

    final MvpCoreStatus coreStatus = MvpAppBridge.watchCoreStatus(ref) ??
        (MvpAppBridge.isMockSupported
            ? ref.watch(customCoreStatusProvider)
            : MvpCoreStatus.disconnected);

    final realActiveProfile = MvpAppBridge.watchActiveProfile(ref);
    final MvpProfileItem activeProfile;
    final bool hasProfile;

    if (realActiveProfile != null && realActiveProfile.id.isNotEmpty) {
      hasProfile = true;
      activeProfile = realActiveProfile;
    } else if (MvpAppBridge.isMockSupported) {
      final mockProfiles = ref.watch(customProfilesProvider);
      final mockCurrentProfileId = ref.watch(customCurrentProfileIdProvider);
      final foundMock = mockProfiles.firstWhere(
        (element) => element.id == mockCurrentProfileId,
        orElse: () => mockProfiles.isNotEmpty
            ? mockProfiles.first
            : const MvpProfileItem(id: '', label: '', url: ''),
      );
      hasProfile = foundMock.id.isNotEmpty;
      activeProfile = foundMock;
    } else {
      hasProfile = false;
      activeProfile = const MvpProfileItem(id: '', label: '', url: '');
    }

    return Scaffold(
      backgroundColor: MvpTheme.bgPrimary,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: 600,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            _MvpHeaderBar(
                              onMinimalTap: _handleMinimalTap,
                              onExportLogs: _handleExportLogs,
                              isExportingLogs: _isExportingLogs,
                            ),
                            const Spacer(flex: 1),
                            const SizedBox(height: 20),
                            _MvpStatusHero(
                              isStart: isStart,
                              coreStatus: coreStatus,
                              onToggle: () => _handleToggleShield(
                                isStart,
                                hasProfile,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Spacer(flex: 1),
                            _MvpQuickInfoCards(
                              isStart: isStart,
                              coreStatus: coreStatus,
                            ),
                            const SizedBox(height: 16),
                            _MvpProfileCard(
                              hasProfile: hasProfile,
                              activeProfile: activeProfile,
                              showInputArea: _showInputArea,
                              onToggleInputArea: (show) {
                                setState(() {
                                  _showInputArea = show;
                                });
                              },
                              urlController: _urlController,
                              isImporting: _isImporting,
                              isUpdating: _isUpdating,
                              onImport: _handleImportConfigZip,
                              onUpdate: () => _handleUpdateSubscription(
                                activeProfile.url,
                              ),
                              onPaste: _handlePaste,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// MARK: - Header Bar

class _MvpHeaderBar extends StatelessWidget {
  final VoidCallback onMinimalTap;
  final VoidCallback onExportLogs;
  final bool isExportingLogs;

  const _MvpHeaderBar({
    required this.onMinimalTap,
    required this.onExportLogs,
    required this.isExportingLogs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title with 5-tap gesture
          GestureDetector(
            onTap: onMinimalTap,
            behavior: HitTestBehavior.opaque,
            child: const Text(
              'Block Ad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MvpTheme.textPrimary,
              ),
            ),
          ),
          // Right action button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: isExportingLogs ? null : onExportLogs,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: isExportingLogs
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MvpTheme.textSecondary,
                        ),
                      )
                    : Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: MvpTheme.textSecondary.withValues(alpha: 0.8),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Toggle Switch

class _MvpToggleSwitch extends StatelessWidget {
  final bool isOn;
  final VoidCallback action;

  const _MvpToggleSwitch({
    required this.isOn,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: GestureDetector(
        onTap: action,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 154,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Capsule Track (130 x 56)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                width: 130,
                height: 56,
                decoration: BoxDecoration(
                  color: isOn ? MvpTheme.activeColor : MvpTheme.inactiveGray,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              // Thumb Container (154 width with oversized thumb)
              AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Active Checkmark
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: isOn ? 1.0 : 0.0,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 250),
                            scale: isOn ? 1.0 : 0.5,
                            child: const Icon(
                              Icons.check_rounded,
                              size: 38,
                              color: MvpTheme.activeColor,
                            ),
                          ),
                        ),
                        // Inactive Circle Ring
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: isOn ? 0.0 : 1.0,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 250),
                            scale: isOn ? 0.5 : 1.0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: MvpTheme.inactiveGray,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Status Hero

class _MvpStatusHero extends StatelessWidget {
  final bool isStart;
  final MvpCoreStatus coreStatus;
  final VoidCallback onToggle;

  const _MvpStatusHero({
    required this.isStart,
    required this.coreStatus,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isConnecting = coreStatus == MvpCoreStatus.connecting;

    final String statusTitle;
    final String statusSubtitle;

    if (isStart) {
      statusTitle = '防护已开启';
      statusSubtitle = '防护运行中 · 智能拦截与隐私保护';
    } else if (isConnecting) {
      statusTitle = '防护启动中';
      statusSubtitle = '正在启动防护服务...';
    } else {
      statusTitle = '防护已暂停';
      statusSubtitle = '点击上方按钮开启防护';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MvpToggleSwitch(
          isOn: isStart || isConnecting,
          action: onToggle,
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            statusTitle,
            key: ValueKey(statusTitle),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: MvpTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            statusSubtitle,
            key: ValueKey(statusSubtitle),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: MvpTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// MARK: - Quick Info Cards

class _MvpQuickInfoCards extends StatelessWidget {
  final bool isStart;
  final MvpCoreStatus coreStatus;

  const _MvpQuickInfoCards({
    required this.isStart,
    required this.coreStatus,
  });

  @override
  Widget build(BuildContext context) {
    final coreStatusText = switch (coreStatus) {
      MvpCoreStatus.connected => '正常',
      MvpCoreStatus.connecting => '启动中',
      MvpCoreStatus.disconnected => '停用',
    };

    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            icon: Icons.shield_rounded,
            title: '防护状态',
            value: isStart ? '已开启' : '未开启',
            isActive: isStart,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.memory_rounded,
            title: '内核状态',
            value: coreStatusText,
            isActive: isStart,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isActive,
  }) {
    final bgFill = isActive
        ? MvpTheme.activeColor.withValues(alpha: 0.12)
        : MvpTheme.inactiveBadgeBg.withValues(alpha: 0.6);
    final iconColor = isActive ? MvpTheme.activeColor : MvpTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MvpTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MvpTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 15,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MvpTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MvpTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Profile Card

class _MvpProfileCard extends StatelessWidget {
  final bool hasProfile;
  final MvpProfileItem activeProfile;
  final bool showInputArea;
  final ValueChanged<bool> onToggleInputArea;
  final TextEditingController urlController;
  final bool isImporting;
  final bool isUpdating;
  final VoidCallback onImport;
  final VoidCallback onUpdate;
  final VoidCallback onPaste;

  const _MvpProfileCard({
    required this.hasProfile,
    required this.activeProfile,
    required this.showInputArea,
    required this.onToggleInputArea,
    required this.urlController,
    required this.isImporting,
    required this.isUpdating,
    required this.onImport,
    required this.onUpdate,
    required this.onPaste,
  });

  String _computeRuleCountStr(MvpProfileItem profile) {
    final rules = profile.rulesCount;
    final totalRules = profile.ruleProvidersTotalRules;
    if (rules != null && rules > 0) {
      if (totalRules != null && totalRules > 0) {
        return '${rules + totalRules} 条';
      }
      return '$rules 条';
    }
    if (totalRules != null && totalRules > 0) {
      return '$totalRules 条';
    }
    return '0 条';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoadedMode = hasProfile && !showInputArea;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MvpTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MvpTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: MvpTheme.textPrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '配置文件',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MvpTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isLoadedMode)
                GestureDetector(
                  onTap: () => onToggleInputArea(true),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: MvpTheme.dangerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 12,
                          color: MvpTheme.dangerText,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '重置',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MvpTheme.dangerText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (hasProfile)
                GestureDetector(
                  onTap: () => onToggleInputArea(false),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: MvpTheme.inactiveBadgeBg.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 12,
                          color: MvpTheme.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '收起',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MvpTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: MvpTheme.borderColor,
          ),
          const SizedBox(height: 14),
          // Content: Loaded State vs Import State
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoadedMode
                ? _buildLoadedState(context)
                : _buildImportState(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context) {
    final activeTitle =
        activeProfile.label.isNotEmpty ? activeProfile.label : 'Block Ad';
    final updateDateStr =
        activeProfile.lastUpdateDate?.formattedUpdateDate ?? '未知';
    final ruleCountStr = _computeRuleCountStr(activeProfile);

    return Row(
      key: const ValueKey('loaded_state'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activeTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: MvpTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '更新于：$updateDateStr',
                style: const TextStyle(
                  fontSize: 13,
                  color: MvpTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '规则：$ruleCountStr',
                style: const TextStyle(
                  fontSize: 13,
                  color: MvpTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: isUpdating ? null : onUpdate,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: MvpTheme.activeColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: MvpTheme.activeColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUpdating) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  const Icon(
                    Icons.sync_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ],
                const Text(
                  '更新',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportState(BuildContext context) {
    return Column(
      key: const ValueKey('import_state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: MvpTheme.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MvpTheme.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: urlController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: MvpTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '粘贴配置文件链接',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: MvpTheme.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.content_paste_rounded,
                  size: 15,
                  color: MvpTheme.textSecondary,
                ),
                onPressed: onPaste,
                splashRadius: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: isImporting ? null : onImport,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: MvpTheme.activeColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: MvpTheme.activeColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isImporting) ...[
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Icon(
                    Icons.download_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                ],
                const Text(
                  '下载并导入',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
