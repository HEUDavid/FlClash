import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mvp_app_bridge_helper.dart';
import 'mvp_models.dart';
import 'mvp_provider.dart';
import 'mvp_restore_helper.dart';

class CustomMvpView extends ConsumerStatefulWidget {
  const CustomMvpView({super.key});

  @override
  ConsumerState<CustomMvpView> createState() => _CustomMvpViewState();
}

class _CustomMvpViewState extends ConsumerState<CustomMvpView> {
  final TextEditingController _urlController = TextEditingController();
  bool _isImporting = false;
  bool _isUpdating = false;
  bool _showInputArea = false;
  bool _isShieldPressed = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleToggleShield(bool currentIsStart) {
    MvpAppBridge.toggleShield(ref, currentIsStart);
    ref.read(customProxyStartProvider.notifier).setStart(!currentIsStart);
  }

  Future<void> _handleUpdateSubscription(String url) async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
    });

    try {
      await updateSubscriptionOrBackup(url);
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  '配置与规则已更新至最新状态',
                  style: TextStyle(letterSpacing: 0.5, fontSize: 13),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '更新失败: $e',
                    style: const TextStyle(letterSpacing: 0.5, fontSize: 13),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    }
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
    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                '请输入有效的配置文件链接',
                style: TextStyle(letterSpacing: 0.5, fontSize: 13),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      await downloadAndRestoreBackup(url);

      ref.read(customProfilesProvider.notifier).addProfileFromBackup(url);
      _urlController.clear();

      if (mounted) {
        setState(() {
          _isImporting = false;
          _showInputArea = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  '规则文件导入成功，防护数据已恢复！',
                  style: TextStyle(letterSpacing: 0.5, fontSize: 13),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '导入失败: $e',
                    style: const TextStyle(letterSpacing: 0.5, fontSize: 13),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLightMode = ref.watch(customMvpProvider);

    // Dynamic dual-mode resolution (App Mode vs Web Preview Mode)
    final bool isStart =
        MvpAppBridge.watchIsStart(ref) ?? ref.watch(customProxyStartProvider);

    final MvpCoreStatus coreStatus =
        MvpAppBridge.watchCoreStatus(ref) ?? ref.watch(customCoreStatusProvider);

    final realActiveProfile = MvpAppBridge.watchActiveProfile(ref);
    final MvpProfileItem activeProfile;
    final bool hasProfile;

    if (realActiveProfile != null && realActiveProfile.id.isNotEmpty) {
      hasProfile = true;
      activeProfile = realActiveProfile;
    } else {
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
    }

    // AdGuard Theme Design System Colors
    final bgPrimary = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    const activeGreen = Color(0xFF10B981);
    const activeGreenDark = Color(0xFF047857);
    final inactiveGray =
        isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
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
                    maxWidth: 540,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 【顶部页边距 1】与底部页边距 5 保持一致 (24px)
                          const SizedBox(height: 24),

                          // 1. Top Header with AdGuard Logo & Mode Switcher
                          _buildAdGuardHeader(
                            isDark,
                            isLightMode,
                            borderColor,
                            activeGreen,
                          ),

                          // 【1与2之间的间距】配合 Spacer，确保在竖屏优雅居中，在横屏/小屏下保底拥有 16px 舒适间距
                          const SizedBox(height: 16),
                          const Spacer(flex: 1),

                          // 2 & 3. Central Protection Shield Hero Widget (大盾牌 2 + 防护文案 3)
                          _buildProtectionShieldHero(
                            isDark: isDark,
                            isStart: isStart,
                            coreStatus: coreStatus,
                            activeGreen: activeGreen,
                            activeGreenDark: activeGreenDark,
                            inactiveGray: inactiveGray,
                          ),

                          const Spacer(flex: 1),
                          // 【3与4之间的间距】增加 3 (防护文案) 与 4 (防护状态/核心状态) 之间的间距
                          const SizedBox(height: 20),

                          // 4. AdGuard Protection Quick Info Pills (防护状态 / 核心状态)
                          _buildQuickInfoCards(
                            isDark,
                            isStart,
                            coreStatus,
                            cardBg,
                            borderColor,
                            activeGreen,
                          ),

                          // 【4与5之间的间距】略微增加 4 与 5 (配置文件) 之间的间距
                          const SizedBox(height: 14),

                          // 5. AdGuard Style Subscription / Profile Card (配置文件)
                          _buildProfileConfigCard(
                            isDark: isDark,
                            hasProfile: hasProfile,
                            activeProfile: activeProfile,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            activeGreen: activeGreen,
                          ),

                          // 【底部页边距 5】与顶部页边距 1 保持一致 (24px)
                          const SizedBox(height: 24),
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
    );
  }

  // 1. AdGuard Header Bar
  Widget _buildAdGuardHeader(
    bool isDark,
    bool isLightMode,
    Color borderColor,
    Color activeGreen,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App Identity with Shield Symbol
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: activeGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: CustomPaint(
                painter: AdGuardShieldPainter(
                  fillColor: activeGreen,
                  borderColor: Colors.transparent,
                  isDark: isDark,
                  isStart: true,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Block Ad',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '智能广告拦截与保护',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Segmented Switcher [ 极简 | 高级 ]
        Container(
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentTab(
                label: '极简',
                isSelected: isLightMode,
                onTap: () =>
                    ref.read(customMvpProvider.notifier).setEnabled(true),
                isDark: isDark,
                activeColor: activeGreen,
              ),
              _buildSegmentTab(
                label: '高级',
                isSelected: !isLightMode,
                onTap: () =>
                    ref.read(customMvpProvider.notifier).setEnabled(false),
                isDark: isDark,
                activeColor: activeGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // 2. Central Protection Shield Hero Area (Fixed bounds & Multi-layer 3D Shader)
  Widget _buildProtectionShieldHero({
    required bool isDark,
    required bool isStart,
    required MvpCoreStatus coreStatus,
    required Color activeGreen,
    required Color activeGreenDark,
    required Color inactiveGray,
  }) {
    final statusTitle = isStart ? '广告防护已开启' : '广告防护已暂停';
    final statusSubtitle = isStart
        ? '防护运行中 · 智能拦截与隐私保护'
        : '点击上方盾牌一键开启防护';

    final offBgColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final offBorderColor =
        isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Interactive 3D Shield Button (Height slightly enlarged: 185x220)
        GestureDetector(
          onTapDown: (_) => setState(() => _isShieldPressed = true),
          onTapUp: (_) => setState(() => _isShieldPressed = false),
          onTapCancel: () => setState(() => _isShieldPressed = false),
          onTap: () => _handleToggleShield(isStart),
          child: AnimatedScale(
            scale: _isShieldPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: 185,
              height: 220,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Outer Ambient Multi-layer Halo Glow
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: isStart ? 1.0 : 0.0,
                    child: Container(
                      width: 185,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeGreen.withValues(alpha: 0.35),
                            blurRadius: 38,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: const Color(0xFF34D399).withValues(alpha: 0.20),
                            blurRadius: 52,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Smooth Color Lerp Shield Canvas with 3D Specular Painter
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: isStart ? 1.0 : 0.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    builder: (context, progress, child) {
                      final currentFill = Color.lerp(
                        offBgColor,
                        activeGreen,
                        progress,
                      )!;
                      final currentBorder = Color.lerp(
                        offBorderColor,
                        const Color(0xFF6EE7B7),
                        progress,
                      )!;

                      return CustomPaint(
                        size: const Size(185, 220),
                        painter: AdGuardShieldPainter(
                          fillColor: currentFill,
                          borderColor: currentBorder,
                          isDark: isDark,
                          isStart: isStart,
                          gradientColors: progress > 0.05
                              ? [
                                  Color.lerp(
                                    offBgColor,
                                    const Color(0xFF4ADE80),
                                    progress,
                                  )!,
                                  Color.lerp(
                                    offBgColor,
                                    activeGreen,
                                    progress,
                                  )!,
                                  Color.lerp(
                                    offBgColor,
                                    activeGreenDark,
                                    progress,
                                  )!,
                                ]
                              : [
                                  isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFE2E8F0),
                                  offBgColor,
                                  isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF94A3B8),
                                ],
                        ),
                        child: child,
                      );
                    },
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          key: ValueKey(isStart),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                              alpha: isStart ? 0.15 : 0.08,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isStart
                                    ? Icons.verified_user_rounded
                                    : Icons.shield_outlined,
                                size: 62,
                                color: isStart
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569)),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(
                                      alpha: isStart ? 0.25 : 0.1,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                Icons.power_settings_new_rounded,
                                size: 22,
                                color: isStart
                                    ? Colors.white.withValues(alpha: 0.95)
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                              ),
                            ],
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

        const SizedBox(height: 18),

        // Status Main Heading Text (Restored clean style without left green dot)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            statusTitle,
            key: ValueKey(statusTitle),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Status Subtitle Text
        SizedBox(
          height: 20,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              statusSubtitle,
              key: ValueKey(statusSubtitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Quick Info Status Pills (AdGuard Style Overview)
  Widget _buildQuickInfoCards(
    bool isDark,
    bool isStart,
    MvpCoreStatus coreStatus,
    Color cardBg,
    Color borderColor,
    Color activeGreen,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            isDark: isDark,
            icon: Icons.shield_rounded,
            title: '防护状态',
            value: isStart ? '已开启' : '未开启',
            cardBg: cardBg,
            borderColor: borderColor,
            activeColor: activeGreen,
            isActive: isStart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoItem(
            isDark: isDark,
            icon: Icons.security_rounded,
            title: '核心状态',
            value: switch (coreStatus) {
              MvpCoreStatus.connected => '已连接',
              MvpCoreStatus.connecting => '连接中',
              MvpCoreStatus.disconnected => '已停用',
            },
            cardBg: cardBg,
            borderColor: borderColor,
            activeColor: activeGreen,
            isActive: isStart,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    required Color cardBg,
    required Color borderColor,
    required Color activeColor,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.12)
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? activeColor
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. AdGuard Style Profile Config Card
  Widget _buildProfileConfigCard({
    required bool isDark,
    required bool hasProfile,
    required MvpProfileItem activeProfile,
    required Color cardBg,
    required Color borderColor,
    required Color activeGreen,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '配置文件',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              if (hasProfile)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showInputArea = !_showInputArea;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Text(
                      _showInputArea ? '收起' : '重置',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: activeGreen,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Animated Switcher between Active Profile view and Input View
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: (hasProfile && !_showInputArea)
                ? _buildActiveProfileDisplay(
                    isDark,
                    activeProfile,
                    borderColor,
                    activeGreen,
                  )
                : _buildImportInputDisplay(isDark, borderColor, activeGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProfileDisplay(
    bool isDark,
    MvpProfileItem activeProfile,
    Color borderColor,
    Color activeGreen,
  ) {
    return Container(
      key: const ValueKey('active_profile_adguard'),
      width: double.infinity,
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeGreen,
              boxShadow: [
                BoxShadow(
                  color: activeGreen.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeProfile.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '远程备份数据 · 规则集已部署生效',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isUpdating
                ? null
                : () => _handleUpdateSubscription(activeProfile.url),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: activeGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: activeGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isUpdating
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: activeGreen,
                          ),
                        )
                      : Icon(
                          Icons.sync_rounded,
                          size: 14,
                          color: activeGreen,
                        ),
                  const SizedBox(width: 4),
                  Text(
                    _isUpdating ? '更新中' : '更新',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: activeGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportInputDisplay(
    bool isDark,
    Color borderColor,
    Color activeGreen,
  ) {
    return Column(
      key: const ValueKey('import_input_adguard'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: TextField(
            controller: _urlController,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: '粘贴配置文件链接...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                onPressed: _handlePaste,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: activeGreen, width: 1),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: FilledButton(
            onPressed: _isImporting ? null : _handleImportSubscription,
            style: FilledButton.styleFrom(
              backgroundColor: activeGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isImporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '下载并导入配置',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Enhanced 3D AdGuard Iconic Shield Custom Painter with Specular Sheen & Bevel Depth
class AdGuardShieldPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final List<Color>? gradientColors;
  final bool isDark;
  final bool isStart;

  AdGuardShieldPainter({
    required this.fillColor,
    required this.borderColor,
    this.gradientColors,
    this.isDark = false,
    this.isStart = true,
  });

  static Path createShieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // High precision curved shield geometry
    path.moveTo(w * 0.20, h * 0.04);
    path.quadraticBezierTo(w * 0.50, 0, w * 0.80, h * 0.04);
    path.cubicTo(w * 0.96, h * 0.06, w * 1.00, h * 0.24, w * 0.95, h * 0.46);
    path.cubicTo(w * 0.90, h * 0.72, w * 0.65, h * 0.94, w * 0.50, h * 0.99);
    path.cubicTo(w * 0.35, h * 0.94, w * 0.10, h * 0.72, w * 0.05, h * 0.46);
    path.cubicTo(w * 0.00, h * 0.24, w * 0.04, h * 0.06, w * 0.20, h * 0.04);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mainPath = createShieldPath(size);

    // 1. Draw Outer Ambient Drop Shadow
    final shadowPaint = Paint()
      ..color = (isStart
              ? const Color(0xFF10B981).withValues(alpha: 0.30)
              : Colors.black.withValues(alpha: isDark ? 0.40 : 0.12))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(mainPath, shadowPaint);
    canvas.restore();

    // 2. Base Gradient Fill
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    if (gradientColors != null && gradientColors!.length >= 2) {
      fillPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors!,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      fillPaint.color = fillColor;
    }
    canvas.drawPath(mainPath, fillPaint);

    // 3. Top Specular Reflection (3D Glossy Surface Overlay)
    final Path sheenPath = Path();
    sheenPath.moveTo(w * 0.20, h * 0.04);
    sheenPath.quadraticBezierTo(w * 0.50, 0, w * 0.80, h * 0.04);
    sheenPath.cubicTo(w * 0.94, h * 0.06, w * 0.98, h * 0.20, w * 0.92, h * 0.38);
    sheenPath.quadraticBezierTo(w * 0.50, h * 0.26, w * 0.08, h * 0.38);
    sheenPath.cubicTo(w * 0.02, h * 0.20, w * 0.06, h * 0.06, w * 0.20, h * 0.04);
    sheenPath.close();

    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isStart ? 0.38 : 0.22),
          Colors.white.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.4))
      ..style = PaintingStyle.fill;
    canvas.drawPath(sheenPath, sheenPaint);

    // 4. Inner Bevel Highlight Rim (3D Chamfer Edge)
    canvas.save();
    canvas.clipPath(mainPath);
    final bevelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isStart ? 0.55 : 0.30),
          Colors.white.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.20),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(mainPath, bevelPaint);
    canvas.restore();

    // 5. Outer Border Stroke
    if (borderColor != Colors.transparent) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawPath(mainPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AdGuardShieldPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.gradientColors != gradientColors ||
      oldDelegate.isDark != isDark ||
      oldDelegate.isStart != isStart;
}
