import 'package:fl_clash/common/shape.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'mvp_theme.dart';
import 'mvp_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MvpAlignPreviewApp(),
    ),
  );
}

class MvpAlignPreviewApp extends StatelessWidget {
  const MvpAlignPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Icon & Text Alignment Lab',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MvpTheme.activeColor,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MvpTheme.activeColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const MvpAlignPreviewView(),
    );
  }
}

class MvpAlignPreviewView extends StatefulWidget {
  const MvpAlignPreviewView({super.key});

  @override
  State<MvpAlignPreviewView> createState() => _MvpAlignPreviewViewState();
}

enum _AlignPreset {
  topAlign('💡 顶部对齐 (CrossAxisAlignment.start + 0位移)', 0.0, 1.0, TextLeadingDistribution.even, 16.0, CrossAxisAlignment.start),
  finalDesign('比例微提 (居中 + 字号×6% 上提)', 0.0, 1.0, TextLeadingDistribution.even, 16.0, CrossAxisAlignment.center),
  planA('方案 A (Icon 14px + 零位移 居中)', 0.0, 1.0, TextLeadingDistribution.even, 14.0, CrossAxisAlignment.center),
  planB('方案 B (Icon 15px + 零位移 居中)', 0.0, 1.0, TextLeadingDistribution.even, 15.0, CrossAxisAlignment.center),
  zeroOffset16('对照组 (Icon 16px + 零位移 居中)', 0.0, 1.0, TextLeadingDistribution.even, 16.0, CrossAxisAlignment.center),
  negative08('方案一 (Icon 16px -0.8px 补偿)', -0.8, 1.0, TextLeadingDistribution.even, 16.0, CrossAxisAlignment.center),
  oldBug('历史误用 (+0.8px 向下加剧)', 0.8, 1.15, TextLeadingDistribution.even, 16.0, CrossAxisAlignment.center),
  custom('自由微调', 0.0, 1.0, TextLeadingDistribution.even, 16.0, CrossAxisAlignment.start);

  final String label;
  final double defaultOffset;
  final double? lineHeight;
  final TextLeadingDistribution leadingDist;
  final double defaultIconSize;
  final CrossAxisAlignment crossAxisAlignment;

  const _AlignPreset(
    this.label,
    this.defaultOffset,
    this.lineHeight,
    this.leadingDist,
    this.defaultIconSize,
    this.crossAxisAlignment,
  );
}

class _MvpAlignPreviewViewState extends State<MvpAlignPreviewView> {
  _AlignPreset _preset = _AlignPreset.topAlign;
  double _offsetY = 0.0;
  double _iconSize = 16.0;
  double _zoomScale = 8.0;
  CrossAxisAlignment _crossAxisAlignment = CrossAxisAlignment.start;

  bool _showCenterLine = true;
  bool _showBoundingBox = true;

  Glyph _selectedGlyph = AppGlyphs.sync;
  String _buttonText = '同步';

  final List<(Glyph, String, String)> _glyphOptions = [
    (AppGlyphs.sync, '同步', 'AppGlyphs.sync'),
    (AppGlyphs.arrowDown, '下载并导入', 'AppGlyphs.arrowDown'),
    (AppGlyphs.check, '确认完成', 'AppGlyphs.check'),
    (AppGlyphs.sliders, '配置文件', 'AppGlyphs.sliders'),
  ];

  void _applyPreset(_AlignPreset preset) {
    setState(() {
      _preset = preset;
      _offsetY = preset == _AlignPreset.finalDesign
          ? MvpIconLabel.opticalOffsetFor(_buttonText, 14)
          : preset.defaultOffset;
      _iconSize = preset.defaultIconSize;
      _crossAxisAlignment = preset.crossAxisAlignment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Icon 与 中文 对齐观察实验室',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: MvpTheme.textPrimary,
        actions: [
          IconButton(
            tooltip: '返回完整 MVP 页面',
            icon: const GlyphIcon(
              AppGlyphs.cardLarge,
              size: 18,
              color: MvpTheme.textSecondary,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomMvpView(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStageCard(),
                  const SizedBox(height: 16),
                  _buildControlsCard(),
                  const SizedBox(height: 16),
                  _buildAnalysisCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageCard() {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: AppShape.md.copyWith(
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '画布观察区',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MvpTheme.textPrimary,
                  ),
                ),
                Text(
                  '缩放: ${_zoomScale.toInt()}x  |  基准: ${_crossAxisAlignment == CrossAxisAlignment.start ? "顶部(start)" : "居中(center)"}  |  Y位移: ${_offsetY >= 0 ? '+' : ''}${_offsetY.toStringAsFixed(1)}px',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: MvpTheme.activeColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Container(
            height: 340,
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: _zoomScale,
                  child: _buildInspectedButton(),
                ),
                if (_showCenterLine)
                  Positioned(
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 1,
                        color: Colors.redAccent.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.lens,
                  size: 8,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '红线为按钮垂直中心几何中轴线 (Center Guideline)',
                    style: TextStyle(
                      fontSize: 11,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
                ),
                if (_showBoundingBox) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyan, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Icon盒',
                    style: TextStyle(fontSize: 11, color: Colors.cyan),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Text盒',
                    style: TextStyle(fontSize: 11, color: Colors.amber),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectedButton() {
    final TextStyle textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: _preset.lineHeight,
      leadingDistribution: _preset.leadingDist,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: ShapeDecoration(
        color: MvpTheme.activeColor,
        shape: AppShape.all(12),
        shadows: [
          BoxShadow(
            color: MvpTheme.activeColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: _crossAxisAlignment,
        children: [
          Container(
            decoration: _showBoundingBox
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.cyan,
                      width: 0.75,
                    ),
                  )
                : null,
            child: GlyphIcon(
              _selectedGlyph,
              size: _iconSize,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Transform.translate(
            offset: Offset(0, _offsetY),
            child: Container(
              decoration: _showBoundingBox
                  ? BoxDecoration(
                      border: Border.all(
                        color: Colors.amber,
                        width: 0.75,
                      ),
                    )
                  : null,
              child: Text(
                _buttonText,
                style: textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: AppShape.md.copyWith(
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. 对齐预设模式对比',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MvpTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _AlignPreset.values.map((preset) {
              final isSelected = _preset == preset;
              return ChoiceChip(
                label: Text(preset.label),
                selected: isSelected,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : MvpTheme.textPrimary,
                ),
                selectedColor: MvpTheme.activeColor,
                backgroundColor: const Color(0xFFF1F5F9),
                shape: AppShape.all(8),
                onSelected: (_) => _applyPreset(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. Icon 尺寸调节',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MvpTheme.textPrimary,
                ),
              ),
              Row(
                children: [14.0, 15.0, 16.0].map((size) {
                  final isSelected = _iconSize == size;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _iconSize = size;
                          _preset = _AlignPreset.custom;
                        });
                      },
                      customBorder: AppShape.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: ShapeDecoration(
                          color: isSelected ? MvpTheme.activeColor : const Color(0xFFF1F5F9),
                          shape: AppShape.xs,
                        ),
                        child: Text(
                          '${size.toInt()}px',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : MvpTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '3. 对齐基准 (CrossAxisAlignment)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MvpTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  (CrossAxisAlignment.start, '顶部对齐 (start)'),
                  (CrossAxisAlignment.center, '居中对齐 (center)'),
                ].map((item) {
                  final isSelected = _crossAxisAlignment == item.$1;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _crossAxisAlignment = item.$1;
                          _preset = _AlignPreset.custom;
                        });
                      },
                      customBorder: AppShape.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: ShapeDecoration(
                          color: isSelected ? MvpTheme.activeColor : const Color(0xFFF1F5F9),
                          shape: AppShape.xs,
                        ),
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : MvpTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4. Y轴微调偏移量 (Offset Y)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MvpTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  _buildStepButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() {
                        _preset = _AlignPreset.custom;
                        _offsetY = (_offsetY - 0.1).clamp(-3.0, 3.0);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 58,
                    alignment: Alignment.center,
                    child: Text(
                      '${_offsetY >= 0 ? '+' : ''}${_offsetY.toStringAsFixed(1)}px',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: MvpTheme.activeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStepButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() {
                        _preset = _AlignPreset.custom;
                        _offsetY = (_offsetY + 0.1).clamp(-3.0, 3.0);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: _offsetY,
            min: -3.0,
            max: 3.0,
            divisions: 60,
            label: '${_offsetY.toStringAsFixed(1)}px',
            activeColor: MvpTheme.activeColor,
            onChanged: (val) {
              setState(() {
                _preset = _AlignPreset.custom;
                _offsetY = double.parse(val.toStringAsFixed(1));
              });
            },
          ),
          const SizedBox(height: 8),
          const Text(
            '3. 辅助观察工具',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MvpTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('中轴红线'),
                selected: _showCenterLine,
                selectedColor: Colors.redAccent.withValues(alpha: 0.15),
                checkmarkColor: Colors.redAccent,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _showCenterLine ? Colors.redAccent : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _showCenterLine = val),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('渲染外框盒'),
                selected: _showBoundingBox,
                selectedColor: Colors.amber.withValues(alpha: 0.15),
                checkmarkColor: Colors.amber[800],
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _showBoundingBox ? Colors.amber[800] : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _showBoundingBox = val),
              ),
              const Spacer(),
              const Text(
                '倍率: ',
                style: TextStyle(fontSize: 12, color: MvpTheme.textSecondary),
              ),
              ...[1.0, 2.0, 4.0, 8.0].map((scale) {
                final isSelected = _zoomScale == scale;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => setState(() => _zoomScale = scale),
                    customBorder: AppShape.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: ShapeDecoration(
                        color: isSelected ? MvpTheme.activeColor : const Color(0xFFF1F5F9),
                        shape: AppShape.xs,
                      ),
                      child: Text(
                        '${scale.toInt()}x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : MvpTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '4. 切换测试文案与图标',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MvpTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _glyphOptions.map((item) {
              final isSelected = _selectedGlyph == item.$1 && _buttonText == item.$2;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlyphIcon(
                      item.$1,
                      size: 14,
                      color: isSelected ? Colors.white : MvpTheme.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(item.$2),
                  ],
                ),
                selected: isSelected,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : MvpTheme.textPrimary,
                ),
                selectedColor: MvpTheme.activeColor,
                backgroundColor: const Color(0xFFF1F5F9),
                shape: AppShape.all(8),
                onSelected: (_) {
                  setState(() {
                    _selectedGlyph = item.$1;
                    _buttonText = item.$2;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: AppShape.xs,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: const Color(0xFFF1F5F9),
          shape: AppShape.xs,
        ),
        child: Icon(
          icon,
          size: 16,
          color: MvpTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: AppShape.md.copyWith(
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: MvpTheme.activeColor),
              SizedBox(width: 6),
              Text(
                '强迫症实测分析结论',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MvpTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '1. 为什么 height: 1.0 时汉字依然明显偏下？\n'
            '字体的排版盒子高度由 ascent（上延）和 descent（下延）决定。中文字符直接坐在 Baseline 基线上，底边距（Descent）极小；而顶端（Ascent）留有大片西文变音符空间，因此字形天生沉在盒子底部。\n\n'
            '2. 为什么历史代码写 +0.8px 会雪上加霜？\n'
            '之前代码写了 Offset(0, 0.8)，相当于把原本就偏下的汉字又向下推了 0.8px，导致底部空隙更小、顶部空隙更大。\n\n'
            '3. 解决方案：\n'
            '通过向上负补偿（例如 Offset(0, -0.8px) 到 -1.0px），把汉字墨水视觉中心向上提，精准落在贯穿 16px 图标正中的红线上。\n\n'
            '4. 顶部对齐（CrossAxisAlignment.start）实测原理：\n'
            'Icon 是 16px，汉字是 14px。当顶部对齐时，14px 文本框顶边紧贴 16px 图标顶边，文本在物理盒模型上自动向上提了恰好 (16-14)/2 = 1.0px！这正好抵消了汉字顶部多出的约 1px Ascent 留白，使得图标顶边墨水与汉字顶笔画自然拉平，且 Y 位移保持绝对的 0。',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: MvpTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
