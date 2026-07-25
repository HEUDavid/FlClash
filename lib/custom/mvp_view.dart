import 'dart:ui';
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

class _CustomMvpViewState extends ConsumerState<CustomMvpView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isImporting = false;
  bool _showInputArea = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('请输入或粘贴有效的订阅链接'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.redAccent.shade700,
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('优化配置导入成功，已自动激活！'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF00C853),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isLightMode = ref.watch(customMvpProvider);
    final isStart = ref.watch(customProxyStartProvider);
    final coreStatus = ref.watch(customCoreStatusProvider);
    final profiles = ref.watch(customProfilesProvider);
    final currentProfileId = ref.watch(customCurrentProfileIdProvider);

    final activeProfile = profiles.firstWhere(
      (element) => element.id == currentProfileId,
      orElse: () => profiles.isNotEmpty
          ? profiles.first
          : const MvpProfileItem(id: '', label: '', url: ''),
    );
    final hasProfile = activeProfile.id.isNotEmpty;

    // 主题色彩定义 - 极简高级感 (Apple & Glassmorphism)
    const activeColor = Color(0xFF00C853); // 活力绿
    const activeGradient = LinearGradient(
      colors: [Color(0xFF00E676), Color(0xFF00B248)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final inactiveGradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
          : [const Color(0xFFF5F5F7), const Color(0xFFE5E5EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF5F6F8),
      body: Stack(
        children: [
          // 1. 背景氛围光 (Ambient Glowing Orb)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isStart
                      ? [
                          activeColor.withOpacity(isDark ? 0.22 : 0.18),
                          activeColor.withOpacity(0.0),
                        ]
                      : [
                          colorScheme.primary.withOpacity(isDark ? 0.10 : 0.08),
                          colorScheme.primary.withOpacity(0.0),
                        ],
                ),
              ),
            ),
          ),
          // 模糊滤镜让光晕更柔和
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: const SizedBox(),
            ),
          ),

          // 2. 主内容区域
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏 (Header)
                _buildHeader(colorScheme, isDark, isLightMode),

                const Spacer(flex: 2),

                // 核心控制区 (Power Button & Status Badge)
                _buildHeroSection(
                  colorScheme,
                  isDark,
                  isStart,
                  coreStatus,
                  activeColor,
                  activeGradient,
                  inactiveGradient,
                ),

                const Spacer(flex: 3),

                // 底部配置卡片 (固定高度 156px，绝不抖动)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: _buildConfigCard(
                    colorScheme,
                    isDark,
                    hasProfile,
                    activeProfile,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 顶部导航与模式切换
  Widget _buildHeader(ColorScheme colorScheme, bool isDark, bool isLightMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 品牌标题 Mi Mi
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mi Mi',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          // 模式切换分段按钮 (Light / Pro)
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFE8E8EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegmentTab(
                  label: 'Light',
                  isSelected: isLightMode,
                  onTap: () => ref.read(customMvpProvider.notifier).setEnabled(true),
                  colorScheme: colorScheme,
                ),
                _buildSegmentTab(
                  label: 'Pro',
                  isSelected: !isLightMode,
                  onTap: () => ref.read(customMvpProvider.notifier).setEnabled(false),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (colorScheme.brightness == Brightness.dark
                  ? const Color(0xFF323238)
                  : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  // 核心连接区 (状态标识 + 呼吸电源大按键)
  Widget _buildHeroSection(
    ColorScheme colorScheme,
    bool isDark,
    bool isStart,
    MvpCoreStatus coreStatus,
    Color activeColor,
    LinearGradient activeGradient,
    LinearGradient inactiveGradient,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态 Badge
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isStart
                ? activeColor.withOpacity(0.12)
                : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFEAECEF)),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isStart
                  ? activeColor.withOpacity(0.4)
                  : Colors.transparent,
            ),
            boxShadow: isStart
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: switch (coreStatus) {
                    MvpCoreStatus.connected => activeColor,
                    MvpCoreStatus.connecting => Colors.amber.shade600,
                    MvpCoreStatus.disconnected =>
                      colorScheme.onSurface.withOpacity(0.35),
                  },
                  boxShadow: isStart
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                switch (coreStatus) {
                  MvpCoreStatus.connected => '已连接',
                  MvpCoreStatus.connecting => '启动连接中...',
                  MvpCoreStatus.disconnected => '未连接',
                },
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isStart
                      ? activeColor
                      : colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // 核心电源大按键 (带呼吸光晕)
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(customProxyStartProvider.notifier).setStart(!isStart);
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = isStart ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: 156,
              height: 156,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isStart ? activeGradient : inactiveGradient,
                boxShadow: [
                  // 底部立体阴影
                  BoxShadow(
                    color: isStart
                        ? activeColor.withOpacity(0.45)
                        : Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                    blurRadius: isStart ? 36 : 20,
                    spreadRadius: isStart ? 8 : 1,
                    offset: const Offset(0, 12),
                  ),
                  // 内部高光边缘模拟
                  if (!isDark && !isStart)
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 10,
                      offset: Offset(-4, -4),
                    ),
                ],
                border: Border.all(
                  color: isStart
                      ? Colors.white.withOpacity(0.3)
                      : (isDark ? Colors.white10 : Colors.white),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    key: ValueKey(isStart),
                    size: 68,
                    color: isStart
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 36),

        // 操作提示文案
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isStart ? '点击按钮 停止连接' : '点击按钮 启动连接',
            key: ValueKey(isStart),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isStart
                  ? activeColor
                  : colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ),
      ],
    );
  }

  // 底部极简配置卡片 (固定高度 156px，彻底无抖动)
  Widget _buildConfigCard(
    ColorScheme colorScheme,
    bool isDark,
    bool hasProfile,
    MvpProfileItem activeProfile,
  ) {
    return Container(
      height: 156, // 绝对固定容器高度
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF19191D).withOpacity(0.85)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '配置文件',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              if (hasProfile)
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showInputArea = !_showInputArea;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _showInputArea
                              ? Icons.unfold_less_rounded
                              : Icons.swap_horiz_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showInputArea ? '收起' : '更换',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 卡片内容切换区 (高度自适应剩余空间)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: (hasProfile && !_showInputArea)
                  ? _buildActiveProfileDisplay(colorScheme, isDark, activeProfile)
                  : _buildImportForm(colorScheme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  // 显示当前激活配置
  Widget _buildActiveProfileDisplay(
    ColorScheme colorScheme,
    bool isDark,
    MvpProfileItem activeProfile,
  ) {
    return Container(
      key: const ValueKey('active_display'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF24242A) : const Color(0xFFF3F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF00C853),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeProfile.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '优选网络节点 · 智能路由已激活',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 导入配置表单
  Widget _buildImportForm(ColorScheme colorScheme, bool isDark) {
    return Column(
      key: const ValueKey('import_form'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 40,
          child: TextField(
            controller: _urlController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '粘贴或输入订阅配置链接...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.link_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                tooltip: '快捷粘贴',
                onPressed: _handlePaste,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF24242A) : const Color(0xFFF0F2F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: FilledButton(
            onPressed: _isImporting ? null : _handleImportSubscription,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '立即导入并激活',
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
