import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
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
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: const Color(0xFF2C2C30),
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      // 自动从远程下载 backup.zip 并恢复数据 (Web 模式下自动隔绝 FFI/sqlite3)
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
                  '备份文件下载成功，数据已完成恢复！',
                  style: TextStyle(letterSpacing: 0.5, fontSize: 13),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '备份恢复失败: $e',
                    style: const TextStyle(letterSpacing: 0.5, fontSize: 13),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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

    // 北欧极简配色调盘 (Nordic Monochromatic & Swiss Accent)
    final bgPrimary = isDark ? const Color(0xFF0F0F11) : const Color(0xFFFAFAFC);
    final cardBg = isDark ? const Color(0xFF17171B) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF28282E) : const Color(0xFFE4E4EB);
    const accentColor = Color(0xFF2563EB); // 皇家蔚蓝 Accent
    const activeStatusColor = Color(0xFF10B981); // 北欧翡翠绿

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // 1. 顶部 Header (包豪斯极简排版)
              _buildSwissHeader(colorScheme, isDark, isLightMode, borderColor),

              const Spacer(flex: 2),

              // 2. 备份恢复配置板块
              _buildNordicConfigCard(
                colorScheme,
                isDark,
                hasProfile,
                activeProfile,
                cardBg,
                borderColor,
                accentColor,
              ),

              const Spacer(flex: 2),

              // 3. 核心主控制板块 (Nordic Minimal Dial Card)
              _buildNordicHeroCard(
                colorScheme,
                isDark,
                isStart,
                coreStatus,
                cardBg,
                borderColor,
                accentColor,
                activeStatusColor,
              ),

              const Spacer(flex: 3),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 1. 北欧极简 Header
  Widget _buildSwissHeader(
    ColorScheme colorScheme,
    bool isDark,
    bool isLightMode,
    Color borderColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 标题标识 (MI MI Tracked Typography)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mi',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 2.5,
                color: isDark ? const Color(0xFFF3F3F6) : const Color(0xFF111115),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 16,
              height: 2,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),

        // 分段式单色模式切换器 [ LIGHT | PRO ]
        Container(
          height: 34,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1D22) : const Color(0xFFEEEEEF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSwissTab(
                label: '极简',
                isSelected: isLightMode,
                onTap: () => ref.read(customMvpProvider.notifier).setEnabled(true),
                isDark: isDark,
              ),
              _buildSwissTab(
                label: '高级',
                isSelected: !isLightMode,
                onTap: () => ref.read(customMvpProvider.notifier).setEnabled(false),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwissTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2D2D35) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF111115))
                : (isDark ? const Color(0xFF6E6E78) : const Color(0xFF8E8E93)),
          ),
        ),
      ),
    );
  }

  // 2. 北欧主控制卡片
  Widget _buildNordicHeroCard(
    ColorScheme colorScheme,
    bool isDark,
    bool isStart,
    MvpCoreStatus coreStatus,
    Color cardBg,
    Color borderColor,
    Color accentColor,
    Color activeStatusColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 极简状态行 (STATUS BADGE)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStart
                      ? activeStatusColor
                      : (isDark ? const Color(0xFF555560) : const Color(0xFFA0A0AA)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                switch (coreStatus) {
                  MvpCoreStatus.connected => '已连接',
                  MvpCoreStatus.connecting => '连接中...',
                  MvpCoreStatus.disconnected => '已停止',
                },
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: isStart
                      ? activeStatusColor
                      : (isDark ? const Color(0xFF8A8A93) : const Color(0xFF6E6E73)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 核心开关按键 (Tactile Minimal Dial)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(customProxyStartProvider.notifier).setStart(!isStart);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStart
                    ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                    : (isDark ? const Color(0xFF222227) : const Color(0xFFF4F4F6)),
                border: Border.all(
                  color: isStart
                      ? accentColor
                      : (isDark ? const Color(0xFF33333C) : const Color(0xFFD8D8E0)),
                  width: isStart ? 2.5 : 1.5,
                ),
                boxShadow: isStart
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.15),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isStart
                        ? accentColor
                        : (isDark ? const Color(0xFF2D2D35) : const Color(0xFFE5E5EA)),
                  ),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    size: 44,
                    color: isStart
                        ? Colors.white
                        : (isDark ? const Color(0xFF8A8A93) : const Color(0xFF6E6E73)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 状态说明
          Text(
            isStart ? '点击停止' : '点击启动',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFFD0D0D5) : const Color(0xFF333338),
            ),
          ),
        ],
      ),
    );
  }

  // 3. 底部配置卡片 (固定高度 156px)
  Widget _buildNordicConfigCard(
    ColorScheme colorScheme,
    bool isDark,
    bool hasProfile,
    MvpProfileItem activeProfile,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      height: 162, // 充足固定容器高度，防止溢出
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题与动作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '配置文件',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? const Color(0xFF777782) : const Color(0xFF8E8E93),
                ),
              ),
              if (hasProfile)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showInputArea = !_showInputArea;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222227) : const Color(0xFFF0F0F3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Text(
                      _showInputArea ? '收起' : '重置',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 卡片内容切换区
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: (hasProfile && !_showInputArea)
                  ? _buildActiveDisplay(isDark, activeProfile, borderColor, accentColor)
                  : _buildImportInput(isDark, borderColor, accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDisplay(
    bool isDark,
    MvpProfileItem activeProfile,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      key: const ValueKey('active_profile'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202025) : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeProfile.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? const Color(0xFFF0F0F4) : const Color(0xFF111115),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '远程备份数据 · 完整配置已恢复',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF7A7A85) : const Color(0xFF777780),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportInput(bool isDark, Color borderColor, Color accentColor) {
    return Column(
      key: const ValueKey('import_input'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 36,
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
                color: isDark ? const Color(0xFF6E6E78) : const Color(0xFF9E9EAA),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                onPressed: _handlePaste,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor, width: 1),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF202025) : const Color(0xFFF7F7FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 34,
          child: FilledButton(
            onPressed: _isImporting ? null : _handleImportSubscription,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
