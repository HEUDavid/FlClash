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
  double _fontSize = 14.0;
  double _zoomScale = 8.0;
  CrossAxisAlignment _crossAxisAlignment = CrossAxisAlignment.start;

  bool _showCenterLine = true;
  bool _showBoundingBox = true;

  Glyph _selectedGlyph = AppGlyphs.sync;
  String _buttonText = '同步';

  final List<(Glyph, String, double, double, String)> _mvpButtons = [
    (AppGlyphs.sync, '同步', 16.0, 14.0, '主操作按钮 (实装: 16/14)'),
    (AppGlyphs.chevronUp, '收起', 14.0, 12.0, '顶部胶囊 (实装: 14/12)'),
    (AppGlyphs.reset, '重置', 14.0, 12.0, '危险胶囊 (实装: 14/12)'),
    (AppGlyphs.arrowDown, '下载并导入', 16.0, 14.0, '长主按钮 (实装: 16/14)'),
    (AppGlyphs.sliders, '配置文件', 18.0, 15.0, '卡片标题 (实装: 18/15)'),
    (AppGlyphs.check, '确认完成', 16.0, 14.0, '常规按钮 (16/14)'),
  ];

  void _selectMvpButton((Glyph, String, double, double, String) item) {
    setState(() {
      _selectedGlyph = item.$1;
      _buttonText = item.$2;
      _iconSize = item.$3;
      _fontSize = item.$4;
    });
  }

  void _applyPreset(_AlignPreset preset) {
    setState(() {
      _preset = preset;
      _offsetY = preset == _AlignPreset.finalDesign
          ? MvpIconLabel.opticalOffsetFor(_buttonText, _fontSize)
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
                  '缩放: ${_zoomScale.toInt()}x  |  基准: ${_crossAxisAlignment == CrossAxisAlignment.start ? "顶部(start)" : "居中(center)"}  |  Icon: ${_iconSize.toInt()}px  |  字号: ${_fontSize.toStringAsFixed(0)}px  |  Y位移: ${_offsetY >= 0 ? '+' : ''}${_offsetY.toStringAsFixed(1)}px',
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
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Icon盒 (${_iconSize.toInt()}px)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Text盒 (${_fontSize.toInt()}px)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_showBoundingBox)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Builder(
                builder: (context) {
                  final double iconCenter = _iconSize / 2;
                  final double iconBottom = _iconSize;
                  final double textBaseTop = _crossAxisAlignment == CrossAxisAlignment.start
                      ? 0.0
                      : (_iconSize - _fontSize) / 2;
                  final double textTop = textBaseTop + _offsetY;
                  final double textCenter = textBaseTop + (_fontSize / 2) + _offsetY;
                  final double textBottom = textBaseTop + _fontSize + _offsetY;
                  return Row(
                    children: [
                      Text(
                        'Icon盒 Y: 顶 0.00 / 中 ${iconCenter.toStringAsFixed(2)} / 底 ${iconBottom.toStringAsFixed(2)} px',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          color: MvpTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Text盒 Y: 顶 ${textTop >= 0 ? '+' : ''}${textTop.toStringAsFixed(2)} / 中 ${textCenter >= 0 ? '+' : ''}${textCenter.toStringAsFixed(2)} / 底 ${textBottom >= 0 ? '+' : ''}${textBottom.toStringAsFixed(2)} px',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInspectedButton() {
    final TextStyle textStyle = TextStyle(
      fontSize: _fontSize,
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
                      color: Colors.black,
                      width: 1.0,
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
                        color: Colors.black,
                        width: 1.0,
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
            '1. MVP 实装按钮场景 (一键切换图标与推荐尺寸)',
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
            children: _mvpButtons.map((item) {
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
                    Text('${item.$2} (${item.$4.toInt()}px)'),
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
                onSelected: (_) => _selectMvpButton(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            '2. 对齐预设模式对比',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3. 字号尺寸调节 (Font Size)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '当前: ${_fontSize.toStringAsFixed(0)}px  (重点对比 12/13/14/15/16px)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildStepButton(
                    icon: Icons.remove,
                    onTap: () {
                      setState(() {
                        _fontSize = (_fontSize - 1.0).clamp(10.0, 24.0);
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  ...[12.0, 13.0, 14.0, 15.0, 16.0].map((size) {
                    final isSelected = _fontSize == size;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkWell(
                        onTap: () => setState(() => _fontSize = size),
                        customBorder: AppShape.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: ShapeDecoration(
                            color: isSelected ? MvpTheme.activeColor : const Color(0xFFF1F5F9),
                            shape: AppShape.xs,
                          ),
                          child: Text(
                            '${size.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : MvpTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  _buildStepButton(
                    icon: Icons.add,
                    onTap: () {
                      setState(() {
                        _fontSize = (_fontSize + 1.0).clamp(10.0, 24.0);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4. Icon 尺寸调节',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MvpTheme.textPrimary,
                ),
              ),
              Row(
                children: [14.0, 15.0, 16.0, 18.0].map((size) {
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
                '5. 对齐基准 (CrossAxisAlignment)',
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
                '6. Y轴微调偏移量 (Offset Y)',
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
            '7. 辅助观察工具',
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
                label: const Text('黑色渲染外框盒'),
                selected: _showBoundingBox,
                selectedColor: Colors.black.withValues(alpha: 0.1),
                checkmarkColor: Colors.black87,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _showBoundingBox ? Colors.black87 : MvpTheme.textSecondary,
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
            '3. 顶部对齐（CrossAxisAlignment.start）实测原理：\n'
            'Icon 是 16px，汉字是 14px。当顶部对齐时，14px 文本框顶边紧贴 16px 图标顶边，文本在物理盒模型上自动向上提了恰好 (16-14)/2 = 1.0px！这正好抵消了汉字顶部多出的约 1px Ascent 留白，使得图标顶边墨水与汉字顶笔画自然拉平，且 Y 位移保持绝对的 0。\n\n'
            '4. “同步 / 下载并导入”主按钮字号观察（14px vs 15px / 16px）：\n'
            '在 42px 主按钮中，当前实装字号为 14px。若感觉字号偏小，可在上方点击 15px 或 16px 查看：15px 墨水更饱满；16px 则与 16px 图标完全等高，顶底双向齐平。\n\n'
            '5. “收起 / 重置”胶囊按钮字号观察（12px vs 13px / 14px）：\n'
            '在 30px 高度小胶囊中，当前实装为 12px 字体搭配 14px 图标。若感觉 12px 略单薄，可在上方切换 13px（微调增重）或 14px（与 14px 图标完全 1:1 等高对齐）。',
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
