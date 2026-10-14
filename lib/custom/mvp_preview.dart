import 'package:fl_clash/common/shape.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:flutter/services.dart';
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
  scheme3Middle(
    '🔥 方案3: 文本引擎 (WidgetSpan.middle)',
    0.0,
    1.0,
    TextLeadingDistribution.even,
    16.0,
    CrossAxisAlignment.center,
    true,
    PlaceholderAlignment.middle,
  ),
  scheme3Baseline(
    '方案3变体: 基线对齐 (WidgetSpan.baseline)',
    0.0,
    1.0,
    TextLeadingDistribution.even,
    16.0,
    CrossAxisAlignment.center,
    true,
    PlaceholderAlignment.baseline,
  ),
  topAlign(
    '原敲定方案: 顶部对齐 (Row.start + 0位移)',
    0.0,
    1.0,
    TextLeadingDistribution.even,
    16.0,
    CrossAxisAlignment.start,
    false,
    PlaceholderAlignment.middle,
  ),
  zeroOffset16(
    '对照组: 几何居中 (Row.center)',
    0.0,
    1.0,
    TextLeadingDistribution.even,
    16.0,
    CrossAxisAlignment.center,
    false,
    PlaceholderAlignment.middle,
  ),
  custom(
    '自由微调',
    0.0,
    1.0,
    TextLeadingDistribution.even,
    16.0,
    CrossAxisAlignment.start,
    false,
    PlaceholderAlignment.middle,
  );

  final String label;
  final double defaultOffset;
  final double? lineHeight;
  final TextLeadingDistribution leadingDist;
  final double defaultIconSize;
  final CrossAxisAlignment crossAxisAlignment;
  final bool isWidgetSpan;
  final PlaceholderAlignment placeholderAlignment;

  const _AlignPreset(
    this.label,
    this.defaultOffset,
    this.lineHeight,
    this.leadingDist,
    this.defaultIconSize,
    this.crossAxisAlignment,
    this.isWidgetSpan,
    this.placeholderAlignment,
  );
}

class _MvpAlignPreviewViewState extends State<MvpAlignPreviewView> {
  _AlignPreset _preset = _AlignPreset.scheme3Middle;
  double _offsetY = 0.0;
  double _iconSize = 16.0;
  double _fontSize = 12.0;
  double _zoomScale = 6.0;
  CrossAxisAlignment _crossAxisAlignment = CrossAxisAlignment.center;
  bool _useWidgetSpan = true;
  PlaceholderAlignment _placeholderAlignment = PlaceholderAlignment.middle;

  bool _showCenterLine = true;
  bool _showIconCenterLine = true;
  bool _showTextCenterLine = true;
  bool _showBoundingBox = true;
  bool _lockVerticalCenter = true;
  bool _isLoading = false;
  bool _compareMode = false;

  Glyph _selectedGlyph = AppGlyphs.sync;
  String _buttonText = '同步';
  String _glyphSearchQuery = '';
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _buttonText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  static const List<(String, Glyph)> _allGlyphs = [
    ('dashboard', AppGlyphs.dashboard),
    ('proxies', AppGlyphs.proxies),
    ('profiles', AppGlyphs.profiles),
    ('requests', AppGlyphs.requests),
    ('clock', AppGlyphs.clock),
    ('history', AppGlyphs.history),
    ('connections', AppGlyphs.connections),
    ('dns', AppGlyphs.dns),
    ('resources', AppGlyphs.resources),
    ('logs', AppGlyphs.logs),
    ('tools', AppGlyphs.tools),
    ('target', AppGlyphs.target),
    ('arrowBack', AppGlyphs.arrowBack),
    ('chevronBack', AppGlyphs.chevronBack),
    ('chevronForward', AppGlyphs.chevronForward),
    ('chevronDown', AppGlyphs.chevronDown),
    ('chevronUp', AppGlyphs.chevronUp),
    ('picker', AppGlyphs.picker),
    ('caretDown', AppGlyphs.caretDown),
    ('arrowUp', AppGlyphs.arrowUp),
    ('arrowDown', AppGlyphs.arrowDown),
    ('scrollToTop', AppGlyphs.scrollToTop),
    ('openExternal', AppGlyphs.openExternal),
    ('undo', AppGlyphs.undo),
    ('redo', AppGlyphs.redo),
    ('sync', AppGlyphs.sync),
    ('refresh', AppGlyphs.refresh),
    ('reset', AppGlyphs.reset),
    ('export', AppGlyphs.export),
    ('upload', AppGlyphs.upload),
    ('add', AppGlyphs.add),
    ('addCircle', AppGlyphs.addCircle),
    ('removeCircle', AppGlyphs.removeCircle),
    ('close', AppGlyphs.close),
    ('check', AppGlyphs.check),
    ('checkDouble', AppGlyphs.checkDouble),
    ('checkCircle', AppGlyphs.checkCircle),
    ('block', AppGlyphs.block),
    ('info', AppGlyphs.info),
    ('warning', AppGlyphs.warning),
    ('error', AppGlyphs.error),
    ('more', AppGlyphs.more),
    ('moreCircle', AppGlyphs.moreCircle),
    ('dragHandle', AppGlyphs.dragHandle),
    ('sort', AppGlyphs.sort),
    ('filter', AppGlyphs.filter),
    ('sortAlpha', AppGlyphs.sortAlpha),
    ('textShort', AppGlyphs.textShort),
    ('wrap', AppGlyphs.wrap),
    ('listAdd', AppGlyphs.listAdd),
    ('edit', AppGlyphs.edit),
    ('compose', AppGlyphs.compose),
    ('delete', AppGlyphs.delete),
    ('clearAll', AppGlyphs.clearAll),
    ('copy', AppGlyphs.copy),
    ('cut', AppGlyphs.cut),
    ('paste', AppGlyphs.paste),
    ('selectAll', AppGlyphs.selectAll),
    ('deselect', AppGlyphs.deselect),
    ('search', AppGlyphs.search),
    ('findReplace', AppGlyphs.findReplace),
    ('save', AppGlyphs.save),
    ('importFile', AppGlyphs.importFile),
    ('file', AppGlyphs.file),
    ('cloud', AppGlyphs.cloud),
    ('cloudDownload', AppGlyphs.cloudDownload),
    ('cloudSync', AppGlyphs.cloudSync),
    ('link', AppGlyphs.link),
    ('send', AppGlyphs.send),
    ('rules', AppGlyphs.rules),
    ('code', AppGlyphs.code),
    ('settings', AppGlyphs.settings),
    ('sliders', AppGlyphs.sliders),
    ('wrench', AppGlyphs.wrench),
    ('toggle', AppGlyphs.toggle),
    ('pin', AppGlyphs.pin),
    ('eye', AppGlyphs.eye),
    ('eyeOff', AppGlyphs.eyeOff),
    ('lock', AppGlyphs.lock),
    ('lockOpen', AppGlyphs.lockOpen),
    ('key', AppGlyphs.key),
    ('password', AppGlyphs.password),
    ('account', AppGlyphs.account),
    ('sparkle', AppGlyphs.sparkle),
    ('bolt', AppGlyphs.bolt),
    ('locate', AppGlyphs.locate),
    ('star', AppGlyphs.star),
    ('puzzle', AppGlyphs.puzzle),
    ('customize', AppGlyphs.customize),
    ('layers', AppGlyphs.layers),
    ('sun', AppGlyphs.sun),
    ('moon', AppGlyphs.moon),
    ('themeAuto', AppGlyphs.themeAuto),
    ('pureBlack', AppGlyphs.pureBlack),
    ('palette', AppGlyphs.palette),
    ('paintbrush', AppGlyphs.paintbrush),
    ('eyedropper', AppGlyphs.eyedropper),
    ('motion', AppGlyphs.motion),
    ('blur', AppGlyphs.blur),
    ('font', AppGlyphs.font),
    ('textSize', AppGlyphs.textSize),
    ('language', AppGlyphs.language),
    ('keyboard', AppGlyphs.keyboard),
    ('photos', AppGlyphs.photos),
    ('camera', AppGlyphs.camera),
    ('qrCode', AppGlyphs.qrCode),
    ('torch', AppGlyphs.torch),
    ('torchOff', AppGlyphs.torchOff),
    ('torchAuto', AppGlyphs.torchAuto),
    ('vpn', AppGlyphs.vpn),
    ('shuffle', AppGlyphs.shuffle),
    ('split', AppGlyphs.split),
    ('speed', AppGlyphs.speed),
    ('dataUsage', AppGlyphs.dataUsage),
    ('memory', AppGlyphs.memory),
    ('cpu', AppGlyphs.cpu),
    ('devices', AppGlyphs.devices),
    ('broom', AppGlyphs.broom),
    ('wifi', AppGlyphs.wifi),
    ('wifiOff', AppGlyphs.wifiOff),
    ('networkCheck', AppGlyphs.networkCheck),
    ('gavel', AppGlyphs.gavel),
    ('appsList', AppGlyphs.appsList),
    ('layoutList', AppGlyphs.layoutList),
    ('layoutTabs', AppGlyphs.layoutTabs),
    ('columnsThree', AppGlyphs.columnsThree),
    ('columnsTwo', AppGlyphs.columnsTwo),
    ('columnsOne', AppGlyphs.columnsOne),
    ('cardLarge', AppGlyphs.cardLarge),
    ('cardMedium', AppGlyphs.cardMedium),
    ('cardSmall', AppGlyphs.cardSmall),
    ('iconTile', AppGlyphs.iconTile),
    ('iconPlain', AppGlyphs.iconPlain),
  ];

  final List<(Glyph, String, double, double, String)> _mvpButtons = [
    (AppGlyphs.sync, '同步', 16.0, 12.0, '主操作按钮 (实装: 16/12)'),
    (AppGlyphs.arrowDown, '下载导入', 16.0, 12.0, '长主按钮 (实装: 16/12)'),
    (AppGlyphs.chevronUp, '收起', 16.0, 12.0, '顶部胶囊 (实装: 16/12)'),
    (AppGlyphs.reset, '重置', 16.0, 12.0, '危险胶囊 (实装: 16/12)'),
    (AppGlyphs.sliders, '配置文件', 16.0, 12.0, '卡片标题 (实装: 16/12)'),
  ];

  void _selectMvpButton((Glyph, String, double, double, String) item) {
    setState(() {
      _selectedGlyph = item.$1;
      _buttonText = item.$2;
      _textController.text = item.$2;
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
      _useWidgetSpan = preset.isWidgetSpan;
      _placeholderAlignment = preset.placeholderAlignment;
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
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStageCard(),
                  const SizedBox(height: 16),
                  _buildControlsCard(),
                  const SizedBox(height: 16),
                  _buildGlyphsListCard(),
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
    final String modeDesc = _useWidgetSpan
        ? '方案3 (WidgetSpan.${_placeholderAlignment.name})'
        : 'Row (${_crossAxisAlignment == CrossAxisAlignment.start ? "start" : "center"})';

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
                Row(
                  children: [
                    const Text(
                      '画布观察区',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: MvpTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: ShapeDecoration(
                        color: _useWidgetSpan
                            ? MvpTheme.activeColor.withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9),
                        shape: AppShape.xs,
                      ),
                      child: Text(
                        _compareMode ? '三方案同屏对比' : modeDesc,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _useWidgetSpan
                              ? MvpTheme.activeColor
                              : MvpTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '缩放: ${_zoomScale.toInt()}x | 字号: ${_fontSize.toInt()}px | 图标: ${_iconSize.toInt()}px',
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
                if (_compareMode)
                  Transform.scale(
                    scale: _zoomScale.clamp(1.0, 5.0),
                    child: _buildComparisonRow(),
                  )
                else
                  Transform.scale(
                    scale: _zoomScale,
                    child: _buildInspectedButton(
                      useWidgetSpan: _useWidgetSpan,
                      placeholderAlignment: _placeholderAlignment,
                      crossAxisAlignment: _crossAxisAlignment,
                      offsetY: _offsetY,
                    ),
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
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lens,
                      size: 8,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '全局中心红线',
                      style: TextStyle(
                        fontSize: 11,
                        color: MvpTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_showIconCenterLine)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Icon中轴白线 (${_iconSize.toInt()}px)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: MvpTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                if (_showTextCenterLine)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Text中轴黑线 (${_fontSize.toInt()}px)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (_showBoundingBox)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '外框盒 (Icon ${_iconSize.toInt()}px / Text ${_fontSize.toInt()}px)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
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
                final double textBaseTop;
                if (_useWidgetSpan) {
                  textBaseTop = (_iconSize - _fontSize) / 2;
                } else if (_crossAxisAlignment == CrossAxisAlignment.start) {
                  textBaseTop = 0.0;
                } else {
                  textBaseTop = (_iconSize - _fontSize) / 2;
                }

                final double textTop = textBaseTop + _offsetY;
                final double textCenter =
                    textBaseTop + (_fontSize / 2) + _offsetY;
                final double textBottom = textBaseTop + _fontSize + _offsetY;
                final double centerDiff = (textCenter - iconCenter).abs();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                    ),
                    if (_useWidgetSpan) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _lockVerticalCenter
                                ? Icons.verified
                                : Icons.check_circle_outline,
                            size: 13,
                            color: MvpTheme.activeColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _lockVerticalCenter
                                  ? '🌟 垂直居中锁生效：红线(按钮中轴) = 白线(Icon中轴) = 黑线(Text中轴) 严格三线合璧'
                                  : (centerDiff < 0.01
                                      ? '方案3: 黑白中线重合，但未锁外框高度 (红线因Descent处于上方)'
                                      : '方案3微调: 中线偏差 Δ = ${centerDiff.toStringAsFixed(2)}px'),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: MvpTheme.activeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔥 方案3 (WidgetSpan)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: MvpTheme.activeColor,
              ),
            ),
            const SizedBox(height: 4),
            _buildInspectedButton(
              useWidgetSpan: true,
              placeholderAlignment: PlaceholderAlignment.middle,
              offsetY: 0.0,
            ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '原敲定 (Row.start)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: MvpTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            _buildInspectedButton(
              useWidgetSpan: false,
              crossAxisAlignment: CrossAxisAlignment.start,
              offsetY: 0.0,
            ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '对照组 (Row.center)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: MvpTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            _buildInspectedButton(
              useWidgetSpan: false,
              crossAxisAlignment: CrossAxisAlignment.center,
              offsetY: 0.0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInspectedButton({
    required bool useWidgetSpan,
    PlaceholderAlignment placeholderAlignment = PlaceholderAlignment.middle,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double offsetY = 0.0,
  }) {
    final TextStyle textStyle = TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: _preset.lineHeight,
      leadingDistribution: _preset.leadingDist,
    );

    final Widget iconContent = _isLoading
        ? SizedBox.square(
            dimension: (_iconSize - 4.0).clamp(8.0, 24.0),
            child: const CircularProgressIndicator(
              strokeWidth: 1.1,
              color: Colors.white,
            ),
          )
        : GlyphIcon(
            _selectedGlyph,
            size: _iconSize,
            color: Colors.white,
          );

    final Widget iconBox = Container(
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
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          iconContent,
          if (_showIconCenterLine)
            Positioned(
              left: -3,
              right: -3,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );

    final Widget textBox = Container(
      decoration: _showBoundingBox
          ? BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 1.0,
              ),
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Text(
            _buttonText,
            style: textStyle,
          ),
          if (_showTextCenterLine)
            Positioned(
              left: -3,
              right: -3,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );

    final Widget innerContent;

    if (useWidgetSpan) {
      innerContent = Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: _fontSize,
            height: _preset.lineHeight,
            leadingDistribution: _preset.leadingDist,
          ),
          children: [
            WidgetSpan(
              alignment: placeholderAlignment,
              baseline: TextBaseline.alphabetic,
              child: iconBox,
            ),
            WidgetSpan(
              alignment: placeholderAlignment,
              baseline: TextBaseline.alphabetic,
              child: const SizedBox(width: 6),
            ),
            WidgetSpan(
              alignment: placeholderAlignment,
              baseline: TextBaseline.alphabetic,
              child: offsetY != 0.0
                  ? Transform.translate(
                      offset: Offset(0, offsetY),
                      child: textBox,
                    )
                  : textBox,
            ),
          ],
        ),
        strutStyle: StrutStyle(
          fontSize: _fontSize,
          height: _preset.lineHeight,
          leadingDistribution: _preset.leadingDist,
          forceStrutHeight: true,
        ),
      );
    } else {
      innerContent = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          iconBox,
          const SizedBox(width: 6),
          Transform.translate(
            offset: Offset(0, offsetY),
            child: textBox,
          ),
        ],
      );
    }

    final double maxElementHeight =
        _iconSize > _fontSize ? _iconSize : _fontSize;
    final Widget finalContent = _lockVerticalCenter
        ? SizedBox(
            height: maxElementHeight,
            child: Center(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: innerContent,
            ),
          )
        : innerContent;

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
      child: finalContent,
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
              final isSelected =
                  _selectedGlyph == item.$1 && _buttonText == item.$2;
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
          const SizedBox(height: 10),
          Container(
            height: 38,
            decoration: ShapeDecoration(
              color: const Color(0xFFF8FAFC),
              shape: AppShape.xs.copyWith(
                side: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  size: 18,
                  color: MvpTheme.activeColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '自定义文字:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MvpTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: (val) {
                      setState(() {
                        _buttonText = val;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '输入自定义文字 (如: 同步 / 配置文件 / 连接代理)...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: MvpTheme.textSecondary,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_buttonText.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _textController.clear();
                      setState(() {
                        _buttonText = '';
                      });
                    },
                    child: const Icon(
                      Icons.cancel,
                      size: 15,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
              ],
            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: isSelected
                                ? MvpTheme.activeColor
                                : const Color(0xFFF1F5F9),
                            shape: AppShape.xs,
                          ),
                          child: Text(
                            '${size.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : MvpTheme.textSecondary,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: isSelected
                                ? MvpTheme.activeColor
                                : const Color(0xFFF1F5F9),
                            shape: AppShape.xs,
                          ),
                          child: Text(
                            '${size.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : MvpTheme.textSecondary,
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
                '5. 排版引擎 / 对齐基准',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MvpTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  (
                    true,
                    PlaceholderAlignment.middle,
                    CrossAxisAlignment.center,
                    '🔥 方案3 (middle)'
                  ),
                  (
                    false,
                    PlaceholderAlignment.middle,
                    CrossAxisAlignment.start,
                    'Row (start)'
                  ),
                  (
                    false,
                    PlaceholderAlignment.middle,
                    CrossAxisAlignment.center,
                    'Row (center)'
                  ),
                ].map((item) {
                  final isSelected = _useWidgetSpan == item.$1 &&
                      (!item.$1 || _placeholderAlignment == item.$2) &&
                      (item.$1 || _crossAxisAlignment == item.$3);
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _useWidgetSpan = item.$1;
                          _placeholderAlignment = item.$2;
                          _crossAxisAlignment = item.$3;
                          _preset = _AlignPreset.custom;
                        });
                      },
                      customBorder: AppShape.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: isSelected
                              ? MvpTheme.activeColor
                              : const Color(0xFFF1F5F9),
                          shape: AppShape.xs,
                        ),
                        child: Text(
                          item.$4,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : MvpTheme.textSecondary,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('三方案同屏对比'),
                selected: _compareMode,
                selectedColor: MvpTheme.activeColor.withValues(alpha: 0.18),
                checkmarkColor: MvpTheme.activeColor,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _compareMode
                      ? MvpTheme.activeColor
                      : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _compareMode = val),
              ),
              FilterChip(
                label: const Text('中轴红线'),
                selected: _showCenterLine,
                selectedColor: Colors.redAccent.withValues(alpha: 0.15),
                checkmarkColor: Colors.redAccent,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _showCenterLine
                      ? Colors.redAccent
                      : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _showCenterLine = val),
              ),
              FilterChip(
                label: const Text('Icon白线'),
                selected: _showIconCenterLine,
                selectedColor: Colors.grey.withValues(alpha: 0.2),
                checkmarkColor: Colors.black87,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _showIconCenterLine
                      ? Colors.black87
                      : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _showIconCenterLine = val),
              ),
              FilterChip(
                label: const Text('Text黑线'),
                selected: _showTextCenterLine,
                selectedColor: Colors.black.withValues(alpha: 0.15),
                checkmarkColor: Colors.black87,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _showTextCenterLine
                      ? Colors.black87
                      : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _showTextCenterLine = val),
              ),
              FilterChip(
                label: const Text('垂直居中锁 (三线合一)'),
                selected: _lockVerticalCenter,
                selectedColor: MvpTheme.activeColor.withValues(alpha: 0.18),
                checkmarkColor: MvpTheme.activeColor,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _lockVerticalCenter
                      ? MvpTheme.activeColor
                      : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) =>
                    setState(() => _lockVerticalCenter = val),
              ),
              FilterChip(
                label: const Text('黑色外框盒'),
                selected: _showBoundingBox,
                selectedColor: Colors.black.withValues(alpha: 0.1),
                checkmarkColor: Colors.black87,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _showBoundingBox
                      ? Colors.black87
                      : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _showBoundingBox = val),
              ),
              FilterChip(
                label: const Text('菊花 Loading'),
                selected: _isLoading,
                selectedColor: MvpTheme.activeColor.withValues(alpha: 0.15),
                checkmarkColor: MvpTheme.activeColor,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color:
                      _isLoading ? MvpTheme.activeColor : MvpTheme.textSecondary,
                ),
                shape: AppShape.all(8),
                onSelected: (val) => setState(() => _isLoading = val),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '倍率: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
                  ...[1.0, 2.0, 4.0, 6.0, 8.0].map((scale) {
                    final isSelected = _zoomScale == scale;
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkWell(
                        onTap: () => setState(() => _zoomScale = scale),
                        customBorder: AppShape.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: isSelected
                                ? MvpTheme.activeColor
                                : const Color(0xFFF1F5F9),
                            shape: AppShape.xs,
                          ),
                          child: Text(
                            '${scale.toInt()}x',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : MvpTheme.textSecondary,
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
              Icon(Icons.insights, size: 16, color: MvpTheme.activeColor),
              SizedBox(width: 6),
              Text(
                '方案对比与跨厂商验证分析',
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
            '【方案3：Text.rich + WidgetSpan(middle) 验证重点】\n'
            '• 技术本质：将图文混排的垂直对齐决策权，从外部纯几何盒模型 (Row) 移交给底层 HarfBuzz / SkParagraph 文本排版引擎。\n'
            '• 为什么能抵抗跨厂商差异：Android 各 ROM（MIUI/HyperOS MiSans、HarmonyOS Sans、OPPO/vivo Sans）的字体度量表 (ascent/descent/xHeight) 各不相同。WidgetSpan 会在运行时动态读取当前加载字体的真实中线位置，自动居中锚定，不依赖任何写死的固定像素补偿。\n\n'
            '【实测操作建议】\n'
            '1. 点击上方「三方案同屏对比」FilterChip，可在同一画布中同步观察：\n'
            '   - 方案3: WidgetSpan.middle\n'
            '   - 对照A: Row.start (顶部贴齐)\n'
            '   - 对照B: Row.center (几何居中)\n'
            '2. 切换上方「1. MVP 实装按钮场景」，在 5 个真实按钮文案与图标下验证光学稳定性。\n'
            '3. 如果方案3验证满意，只需将 `mvp_view.dart` 中的 `MvpIconLabel` 改为 `Text.rich(WidgetSpan)` 即可全局无感生效。',
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

  Widget _buildGlyphsListCard() {
    final filtered = _glyphSearchQuery.isEmpty
        ? _allGlyphs
        : _allGlyphs
            .where(
              (g) => g.$1
                  .toLowerCase()
                  .contains(_glyphSearchQuery.toLowerCase()),
            )
            .toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const GlyphIcon(
                    AppGlyphs.iconTile,
                    size: 16,
                    color: MvpTheme.activeColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AppGlyphs 图标清单',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: AppShape.xs,
                    ),
                    child: Text(
                      '${filtered.length} / ${_allGlyphs.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: MvpTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                '点击行直接装载至上方实验室',
                style: TextStyle(
                  fontSize: 11,
                  color: MvpTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 38,
            decoration: ShapeDecoration(
              color: const Color(0xFFF8FAFC),
              shape: AppShape.xs.copyWith(
                side: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  size: 18,
                  color: MvpTheme.activeColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '测试文字:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MvpTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: (val) {
                      setState(() {
                        _buttonText = val;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '输入自定义文字，点击下方任意图标实时装载测试...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: MvpTheme.textSecondary,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_buttonText.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _textController.clear();
                      setState(() {
                        _buttonText = '';
                      });
                    },
                    child: const Icon(
                      Icons.cancel,
                      size: 15,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 38,
            decoration: ShapeDecoration(
              color: const Color(0xFFF8FAFC),
              shape: AppShape.xs.copyWith(
                side: BorderSide(
                  color: Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 16,
                  color: MvpTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _glyphSearchQuery = val.trim()),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: MvpTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '搜索图标名称 (如 sliders, sync, check, arrow)...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: MvpTheme.textSecondary,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_glyphSearchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _glyphSearchQuery = ''),
                    child: const Icon(
                      Icons.cancel,
                      size: 15,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: ShapeDecoration(
              color: const Color(0xFFF1F5F9),
              shape: AppShape.xs,
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '常量名称',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    '显示图标',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    '操作',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: MvpTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text(
                '未找到匹配的图标',
                style: TextStyle(
                  fontSize: 12,
                  color: MvpTheme.textSecondary,
                ),
              ),
            )
          else
            for (var i = 0; i < filtered.length; i++)
              _buildGlyphRow(i, filtered[i].$1, filtered[i].$2),
        ],
      ),
    );
  }

  Widget _buildGlyphRow(int index, String name, Glyph glyph) {
    final isSelected = _selectedGlyph == glyph;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGlyph = glyph;
          });
        },
        customBorder: AppShape.xs,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: ShapeDecoration(
            color: isSelected
                ? MvpTheme.activeColor.withValues(alpha: 0.10)
                : (index.isEven
                    ? const Color(0xFFFAFAFC)
                    : Colors.white),
            shape: AppShape.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isSelected
                        ? MvpTheme.activeColor
                        : MvpTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'AppGlyphs.$name',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? MvpTheme.activeColor
                              : MvpTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: 'AppGlyphs.$name'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已复制 AppGlyphs.$name 到剪贴板'),
                            duration: const Duration(milliseconds: 1200),
                            behavior: SnackBarBehavior.floating,
                            width: 280,
                          ),
                        );
                      },
                      customBorder: AppShape.xs,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.copy,
                          size: 13,
                          color: isSelected
                              ? MvpTheme.activeColor
                              : MvpTheme.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 72,
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: isSelected
                          ? MvpTheme.activeColor
                          : const Color(0xFFF1F5F9),
                      shape: AppShape.all(6),
                    ),
                    child: GlyphIcon(
                      glyph,
                      size: 16,
                      color: isSelected ? Colors.white : MvpTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: isSelected
                        ? MvpTheme.activeColor
                        : Colors.transparent,
                    shape: AppShape.xs,
                  ),
                  child: Text(
                    isSelected ? '已装载' : '装载',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : MvpTheme.textSecondary,
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
