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
  topAlign('💡 敲定方案: 顶部对齐 (start + 0位移)', 0.0, 1.0, TextLeadingDistribution.even, 15.0, CrossAxisAlignment.start),
  zeroOffset16('对照组: 居中未位移 (center)', 0.0, 1.0, TextLeadingDistribution.even, 15.0, CrossAxisAlignment.center),
  custom('自由微调', 0.0, 1.0, TextLeadingDistribution.even, 15.0, CrossAxisAlignment.start);

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
  double _iconSize = 15.0;
  double _fontSize = 13.0;
  double _zoomScale = 8.0;
  CrossAxisAlignment _crossAxisAlignment = CrossAxisAlignment.start;

  bool _showCenterLine = true;
  bool _showBoundingBox = true;
  bool _isLoading = false;

  Glyph _selectedGlyph = AppGlyphs.sync;
  String _buttonText = '同步';

  final List<(Glyph, String, double, double, String)> _mvpButtons = [
    (AppGlyphs.sync, '同步', 15.0, 13.0, '主操作按钮 (实装: 15/13)'),
    (AppGlyphs.arrowDown, '下载并导入', 15.0, 13.0, '长主按钮 (实装: 15/13)'),
    (AppGlyphs.chevronUp, '收起', 13.0, 12.0, '顶部胶囊 (实装: 13/12)'),
    (AppGlyphs.reset, '重置', 13.0, 12.0, '危险胶囊 (实装: 13/12)'),
    (AppGlyphs.sliders, '配置文件', 15.0, 13.0, '卡片标题 (实装: 15/13)'),
    (AppGlyphs.check, '确认完成', 15.0, 13.0, '常规按钮 (15/13)'),
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
      _offsetY = preset.defaultOffset;
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
            width: _iconSize,
            height: _iconSize,
            alignment: Alignment.center,
            decoration: _showBoundingBox
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  )
                : null,
            child: _isLoading
                ? SizedBox.square(
                    dimension: _iconSize * (10.5 / 15),
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.3,
                      color: Colors.white,
                    ),
                  )
                : GlyphIcon(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4. Icon 尺寸调节',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '当前: ${_iconSize.toStringAsFixed(0)}px  (支持 10/12/13/14/15/16/18px)',
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
                        _iconSize = (_iconSize - 1.0).clamp(8.0, 24.0);
                        _preset = _AlignPreset.custom;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  ...[10.0, 12.0, 13.0, 14.0, 15.0, 16.0, 18.0].map((size) {
                    final isSelected = _iconSize == size;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _iconSize = size;
                            _preset = _AlignPreset.custom;
                          });
                        },
                        customBorder: AppShape.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
                        _iconSize = (_iconSize + 1.0).clamp(8.0, 24.0);
                        _preset = _AlignPreset.custom;
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
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('菊花 Loading'),
                selected: _isLoading,
                selectedColor: MvpTheme.activeColor.withValues(alpha: 0.15),
                checkmarkColor: MvpTheme.activeColor,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _isLoading ? MvpTheme.activeColor : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _isLoading = val),
              ),
              const Spacer(),
              const Text(
                '倍率: ',
                style: TextStyle(fontSize: 12, color: MvpTheme.textSecondary),
              ),
              ...[1.0, 2.0, 4.0, 6.0, 8.0].map((scale) {
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
          const Text(
            '【最终敲定方案】\n'
            '• 对齐基准：顶部对齐 (CrossAxisAlignment.start) + 0位移 (Offset.zero)\n'
            '• 排版参数：height: 1.0, leadingDistribution: TextLeadingDistribution.even\n\n'
            '【实装按钮规格规范】\n'
            '1. 同步 / 下载并导入：字体 13px，Icon 15px (含菊花 Loading)\n'
            '2. 收起 / 重置：字体 12px，Icon 13px\n'
            '3. 配置文件：字体 13px，Icon 15px\n\n'
            '【设计原理】\n'
            '中文字符由于天然缺少西方变音符，在排版盒中沉在底部。在顶部对齐模式下，文本框顶边紧贴图标顶边，使得图标顶边缘墨水与汉字顶端笔画自然拉平，在无需任何 Magic Number 负位移的情况下，实现跨平台最稳健、最纯粹的像素级对齐。',
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
