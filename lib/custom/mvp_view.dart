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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // 1. Top Header with AdGuard Logo & Mode Switcher
              _buildAdGuardHeader(isDark, isLightMode, borderColor, activeGreen),

              const Spacer(flex: 1),

              // 2. Central Protection Shield Hero Widget (AdGuard Style)
              _buildProtectionShieldHero(
                isDark: isDark,
                isStart: isStart,
                coreStatus: coreStatus,
                activeGreen: activeGreen,
                activeGreenDark: activeGreenDark,
                inactiveGray: inactiveGray,
              ),

              const Spacer(flex: 1),

              // 3. AdGuard Protection Quick Info Pills
              _buildQuickInfoCards(isDark, isStart, coreStatus, cardBg, borderColor, activeGreen),

              const SizedBox(height: 16),

              // 4. AdGuard Style Subscription / Profile Card
              _buildProfileConfigCard(
                isDark: isDark,
                hasProfile: hasProfile,
                activeProfile: activeProfile,
                cardBg: cardBg,
                borderColor: borderColor,
                activeGreen: activeGreen,
              ),

              const SizedBox(height: 24),
            ],
          ),
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: activeGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: CustomPaint(
                painter: AdGuardShieldPainter(
                  fillColor: activeGreen,
                  borderColor: Colors.transparent,
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
          height: 34,
          padding: const EdgeInsets.all(2),
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

  // 2. Central Protection Shield Hero Area (Fixed bounds to prevent layout jitter)
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
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final offBorderColor =
        isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Badge Pill (Strict fixed 170x32 bounds to prevent width/height jitter)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 170,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isStart
                ? activeGreen.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isStart
                  ? activeGreen.withValues(alpha: 0.3)
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStart ? activeGreen : inactiveGray,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 124,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    switch (coreStatus) {
                      MvpCoreStatus.connected => 'PROTECTED · 已保护',
                      MvpCoreStatus.connecting => 'CONNECTING · 连接中',
                      MvpCoreStatus.disconnected => 'DISABLED · 未保护',
                    },
                    key: ValueKey(coreStatus),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isStart
                          ? activeGreen
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Main AdGuard Interactive Shield Button (Strict fixed 160x190 bounds)
        GestureDetector(
          onTap: () => _handleToggleShield(isStart),
          child: SizedBox(
            width: 160,
            height: 190,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Fixed Glow Layer (Alpha fade only, zero spread/size change)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isStart ? 1.0 : 0.0,
                  child: Container(
                    width: 150,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: activeGreen.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),

                // Smooth Color Lerp Shield Canvas
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
                      const Color(0xFF34D399),
                      progress,
                    )!;

                    return CustomPaint(
                      size: const Size(160, 190),
                      painter: AdGuardShieldPainter(
                        fillColor: currentFill,
                        borderColor: currentBorder,
                        gradientColors: progress > 0.1
                            ? [
                                Color.lerp(
                                  offBgColor,
                                  const Color(0xFF34D399),
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
                            : null,
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        key: ValueKey(isStart),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Icon(
                            isStart
                                ? Icons.verified_user_rounded
                                : Icons.shield_outlined,
                            size: 60,
                            color: isStart
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            Icons.power_settings_new_rounded,
                            size: 20,
                            color: isStart
                                ? Colors.white.withValues(alpha: 0.9)
                                : (isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8)),
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

        const SizedBox(height: 24),

        // Status Main Heading Text (Smooth cross-fade)
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

        // Status Subtitle Text (Fixed height wrapper to prevent text shift)
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
        const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
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
                    fontSize: 10,
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
                      _showInputArea ? '收起' : '更换/重置',
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

/// AdGuard Iconic Shield Custom Painter
class AdGuardShieldPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final List<Color>? gradientColors;

  AdGuardShieldPainter({
    required this.fillColor,
    required this.borderColor,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Classic curved shield path calculation
    path.moveTo(w * 0.15, 0);
    path.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.85, 0);
    path.cubicTo(w * 1.02, h * 0.35, w * 0.92, h * 0.72, w * 0.5, h);
    path.cubicTo(w * 0.08, h * 0.72, -w * 0.02, h * 0.35, w * 0.15, 0);
    path.close();

    if (gradientColors != null && gradientColors!.length >= 2) {
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors!,
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else {
      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    if (borderColor != Colors.transparent) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AdGuardShieldPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.gradientColors != gradientColors;
}
