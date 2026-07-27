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
  bool _isShieldToggling = false;

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

  void _handleToggleShield(bool currentIsStart) {
    if (_isShieldToggling) return;
    _isShieldToggling = true;

    MvpAppBridge.toggleShield(ref, currentIsStart);
    ref.read(customProxyStartProvider.notifier).setStart(!currentIsStart);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _isShieldToggling = false;
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
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
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
      if (!mounted) return;

      ref.read(customProfilesProvider.notifier).addProfileFromBackup(url);
      _urlController.clear();

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
                '导入成功',
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
    } catch (e) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLightMode = ref.watch(customMvpProvider);

    // Dynamic dual-mode resolution (App Mode vs Web Preview Mode)
    final bool isStart =
        MvpAppBridge.watchIsStart(ref) ?? ref.watch(customProxyStartProvider);

    final MvpCoreStatus coreStatus = MvpAppBridge.watchCoreStatus(ref) ??
        ref.watch(customCoreStatusProvider);

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
    final bgPrimary =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    const activeGreen = Color(0xFF10B981);
    const activeGreenDark = Color(0xFF047857);
    final inactiveGray =
        isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactWidth = constraints.maxWidth < 360;
            final bool isWideWidth = constraints.maxWidth >= 600;
            final bool isCompactHeight = constraints.maxHeight < 680;

            final double horizontalPadding =
                isCompactWidth ? 14.0 : (isWideWidth ? 28.0 : 20.0);
            final double maxContentWidth = isWideWidth ? 580.0 : 540.0;
            final double verticalEdgePadding = isCompactHeight ? 14.0 : 24.0;
            final double headerBottomGap = isCompactHeight ? 10.0 : 16.0;
            final double shieldBottomGap = isCompactHeight ? 14.0 : 20.0;
            final double cardsBottomGap = isCompactHeight ? 12.0 : 14.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: verticalEdgePadding),

                          // 1. Top Header with AdGuard Logo & Mode Switcher
                          _buildAdGuardHeader(
                            isDark: isDark,
                            isLightMode: isLightMode,
                            borderColor: borderColor,
                            activeGreen: activeGreen,
                            isCompactWidth: isCompactWidth,
                          ),

                          SizedBox(height: headerBottomGap),
                          const Spacer(flex: 1),

                          // 2 & 3. Central Protection Shield Hero Widget
                          _buildProtectionShieldHero(
                            isDark: isDark,
                            isStart: isStart,
                            coreStatus: coreStatus,
                            activeGreen: activeGreen,
                            activeGreenDark: activeGreenDark,
                            inactiveGray: inactiveGray,
                            isCompactHeight: isCompactHeight,
                            isCompactWidth: isCompactWidth,
                          ),

                          const Spacer(flex: 1),
                          SizedBox(height: shieldBottomGap),

                          // 4. AdGuard Protection Quick Info Pills
                          _buildQuickInfoCards(
                            isDark: isDark,
                            isStart: isStart,
                            coreStatus: coreStatus,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            activeGreen: activeGreen,
                            isCompactWidth: isCompactWidth,
                          ),

                          SizedBox(height: cardsBottomGap),

                          // 5. AdGuard Style Subscription / Profile Card
                          _buildProfileConfigCard(
                            isDark: isDark,
                            hasProfile: hasProfile,
                            activeProfile: activeProfile,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            activeGreen: activeGreen,
                            isCompactWidth: isCompactWidth,
                          ),

                          SizedBox(height: verticalEdgePadding),
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
  Widget _buildAdGuardHeader({
    required bool isDark,
    required bool isLightMode,
    required Color borderColor,
    required Color activeGreen,
    required bool isCompactWidth,
  }) {
    final double logoSize = isCompactWidth ? 30.0 : 34.0;
    final double iconSize = isCompactWidth ? 14.0 : 16.0;
    final double titleSize = isCompactWidth ? 16.0 : 18.0;
    final double subtitleSize = isCompactWidth ? 9.5 : 10.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App Identity with Shield Symbol
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
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
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: isCompactWidth ? 8.0 : 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Block Ad',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: titleSize,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '智能广告拦截与保护',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: subtitleSize,
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
          height: isCompactWidth ? 34.0 : 36.0,
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
                isCompactWidth: isCompactWidth,
              ),
              _buildSegmentTab(
                label: '高级',
                isSelected: !isLightMode,
                onTap: () =>
                    ref.read(customMvpProvider.notifier).setEnabled(false),
                isDark: isDark,
                isCompactWidth: isCompactWidth,
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
    required bool isCompactWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isCompactWidth ? 11.0 : 14.0,
          vertical: 4.0,
        ),
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
            fontSize: isCompactWidth ? 10.5 : 11.0,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // 2. Central Protection Shield Hero Area (Responsive bounds & Multi-layer 3D Shader)
  Widget _buildProtectionShieldHero({
    required bool isDark,
    required bool isStart,
    required MvpCoreStatus coreStatus,
    required Color activeGreen,
    required Color activeGreenDark,
    required Color inactiveGray,
    required bool isCompactHeight,
    required bool isCompactWidth,
  }) {
    final statusTitle = isStart ? '广告防护已开启' : '广告防护已暂停';
    final statusSubtitle = isStart ? '防护运行中 · 智能拦截与隐私保护' : '点击上方盾牌一键开启防护';

    final offBgColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final offBorderColor =
        isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final double shieldWidth = isCompactHeight ? 155.0 : 185.0;
    final double shieldHeight = isCompactHeight ? 185.0 : 220.0;
    final double mainIconSize = isCompactHeight ? 52.0 : 62.0;
    final double subIconSize = isCompactHeight ? 18.0 : 22.0;
    final double titleFontSize = isCompactWidth ? 20.0 : 22.0;
    final double subtitleFontSize = isCompactWidth ? 12.0 : 13.0;
    final double titleGap = isCompactHeight ? 12.0 : 18.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Interactive 3D Shield Button
        GestureDetector(
          onTapDown: (_) => setState(() => _isShieldPressed = true),
          onTapUp: (_) => setState(() => _isShieldPressed = false),
          onTapCancel: () => setState(() => _isShieldPressed = false),
          onTap: () => _handleToggleShield(isStart),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isShieldPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: shieldWidth,
              height: shieldHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Outer Ambient Multi-layer Halo Glow
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: isStart ? 1.0 : 0.0,
                    child: Container(
                      width: shieldWidth,
                      height: shieldHeight,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeGreen.withValues(alpha: 0.35),
                            blurRadius: isCompactHeight ? 30.0 : 38.0,
                            spreadRadius: isCompactHeight ? 2.0 : 4.0,
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF34D399).withValues(alpha: 0.20),
                            blurRadius: isCompactHeight ? 40.0 : 52.0,
                            spreadRadius: isCompactHeight ? 6.0 : 10.0,
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
                        size: Size(shieldWidth, shieldHeight),
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
                          padding:
                              EdgeInsets.all(isCompactHeight ? 12.0 : 14.0),
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
                                size: mainIconSize,
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
                                size: subIconSize,
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

        SizedBox(height: titleGap),

        // Status Main Heading Text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            statusTitle,
            key: ValueKey(statusTitle),
            style: TextStyle(
              fontSize: titleFontSize,
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
                fontSize: subtitleFontSize,
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

  // 3. Quick Info Status Pills
  Widget _buildQuickInfoCards({
    required bool isDark,
    required bool isStart,
    required MvpCoreStatus coreStatus,
    required Color cardBg,
    required Color borderColor,
    required Color activeGreen,
    required bool isCompactWidth,
  }) {
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
            isCompactWidth: isCompactWidth,
          ),
        ),
        SizedBox(width: isCompactWidth ? 8.0 : 12.0),
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
            isCompactWidth: isCompactWidth,
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
    required bool isCompactWidth,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactWidth ? 10.0 : 14.0,
        vertical: isCompactWidth ? 11.0 : 13.0,
      ),
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
            padding: EdgeInsets.all(isCompactWidth ? 6.0 : 8.0),
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
              size: isCompactWidth ? 16.0 : 18.0,
              color: isActive
                  ? activeColor
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ),
          SizedBox(width: isCompactWidth ? 8.0 : 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompactWidth ? 10.5 : 11.0,
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
                    fontSize: isCompactWidth ? 12.0 : 13.0,
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
    required bool isCompactWidth,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompactWidth ? 14.0 : 16.0),
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
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                    isDark: isDark,
                    activeProfile: activeProfile,
                    borderColor: borderColor,
                    activeGreen: activeGreen,
                    isCompactWidth: isCompactWidth,
                  )
                : _buildImportInputDisplay(
                    isDark: isDark,
                    borderColor: borderColor,
                    activeGreen: activeGreen,
                    isCompactWidth: isCompactWidth,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProfileDisplay({
    required bool isDark,
    required MvpProfileItem activeProfile,
    required Color borderColor,
    required Color activeGreen,
    required bool isCompactWidth,
  }) {
    return SizedBox(
      key: const ValueKey('active_profile_adguard'),
      height: 100,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isCompactWidth ? 12.0 : 14.0,
          vertical: 12.0,
        ),
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
            SizedBox(width: isCompactWidth ? 8.0 : 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeProfile.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isCompactWidth ? 12.0 : 13.0,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '在线配置集合',
                    style: TextStyle(
                      fontSize: isCompactWidth ? 10.0 : 11.0,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isCompactWidth ? 6.0 : 8.0),
            GestureDetector(
              onTap: _isUpdating
                  ? null
                  : () => _handleUpdateSubscription(activeProfile.url),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      activeGreen.withValues(alpha: _isUpdating ? 0.08 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        activeGreen.withValues(alpha: _isUpdating ? 0.2 : 0.3),
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
      ),
    );
  }

  Widget _buildImportInputDisplay({
    required bool isDark,
    required Color borderColor,
    required Color activeGreen,
    required bool isCompactWidth,
  }) {
    return SizedBox(
      key: const ValueKey('import_input_adguard'),
      height: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        SizedBox(
          height: 44,
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
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
              fillColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
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
                    '下载并导入',
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
    sheenPath.cubicTo(
        w * 0.94, h * 0.06, w * 0.98, h * 0.20, w * 0.92, h * 0.38);
    sheenPath.quadraticBezierTo(w * 0.50, h * 0.26, w * 0.08, h * 0.38);
    sheenPath.cubicTo(
        w * 0.02, h * 0.20, w * 0.06, h * 0.06, w * 0.20, h * 0.04);
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
