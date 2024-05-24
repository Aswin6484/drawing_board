import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../paint_contents.dart';
import 'helper/safe_value_notifier.dart';

/// 绘制参数
class DrawConfig {
  DrawConfig({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.red,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 4,
    this.style = PaintingStyle.stroke,
  });

  DrawConfig.def({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.red,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 4,
    this.style = PaintingStyle.stroke,
  });

  /// 旋转的角度（0:0,1:90,2:180,3:270）
  final int angle;

  final Type contentType;

  final int fingerCount;

  final Size? size;

  /// Paint相关
  final BlendMode blendMode;
  final Color color;
  final ColorFilter? colorFilter;
  final FilterQuality filterQuality;
  final ui.ImageFilter? imageFilter;
  final bool invertColors;
  final bool isAntiAlias;
  final MaskFilter? maskFilter;
  final Shader? shader;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final double strokeWidth;
  final PaintingStyle style;

  /// 生成paint
  Paint get paint => Paint()
    ..blendMode = blendMode
    ..color = color
    ..colorFilter = colorFilter
    ..filterQuality = filterQuality
    ..imageFilter = imageFilter
    ..invertColors = invertColors
    ..isAntiAlias = isAntiAlias
    ..maskFilter = maskFilter
    ..shader = shader
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin
    ..strokeWidth = strokeWidth
    ..style = style;

  DrawConfig copyWith({
    Type? contentType,
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeWidth,
    PaintingStyle? style,
    int? angle,
    int? fingerCount,
    Size? size,
  }) {
    return DrawConfig(
      contentType: contentType ?? this.contentType,
      angle: angle ?? this.angle,
      blendMode: blendMode ?? this.blendMode,
      color: color ?? this.color,
      colorFilter: colorFilter ?? this.colorFilter,
      filterQuality: filterQuality ?? this.filterQuality,
      imageFilter: imageFilter ?? this.imageFilter,
      invertColors: invertColors ?? this.invertColors,
      isAntiAlias: isAntiAlias ?? this.isAntiAlias,
      maskFilter: maskFilter ?? this.maskFilter,
      shader: shader ?? this.shader,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      style: style ?? this.style,
      fingerCount: fingerCount ?? this.fingerCount,
      size: size ?? this.size,
    );
  }
}

enum DrawingBoardStates { DrawingState, SelectionState }

/// 绘制控制器
class DrawingController extends ChangeNotifier {
  DrawingController({DrawConfig? config, PaintContent? content}) {
    _history = <PaintContent>[];
    _currentIndex = 0;
    realPainter = RePaintNotifier();
    painter = RePaintNotifier();
    drawConfig = SafeValueNotifier<DrawConfig>(
        config ?? DrawConfig.def(contentType: SimpleLine));
    setPaintContent(content ?? SimpleLine());
    bounds = const Rect.fromLTRB(0, 0, 10, 10);
  }
  DrawingBoardStates drawingBoardStates = DrawingBoardStates.DrawingState;

  /// 绘制开始点
  Offset? _startPoint;

  /// 画板数据Key
  late GlobalKey painterKey = GlobalKey();

  /// 控制器
  late SafeValueNotifier<DrawConfig> drawConfig;

  /// 最后一次绘制的内容
  late PaintContent _paintContent;

  /// 当前绘制内容
  PaintContent? currentContent;

  /// 底层绘制内容(绘制记录)
  late List<PaintContent> _history;
  final ValueNotifier<String> textNotifier = ValueNotifier('');

  /// 当前controller是否存在
  bool _mounted = true;
  PaintContent? _selectedContent;
  PaintContent? get selectedContent => _selectedContent;

  /// 获取绘制图层/历史
  List<PaintContent> get getHistory => _history;

  /// 步骤指针
  late int _currentIndex;

  /// 表层画布刷新控制
  RePaintNotifier? painter;

  /// 底层画布刷新控制
  RePaintNotifier? realPainter;

  /// 获取当前步骤索引
  int get currentIndex => _currentIndex;

  PaintContent? draggingContent;
  Offset? draggingOffset;

  /// 获取当前颜色
  Color get getColor => drawConfig.value.color;

  /// 能否进行绘制
  bool get couldDraw =>
      drawConfig.value.fingerCount <= 1 &&
      drawConfig.value.contentType != EmptyContent;

  /// 开始绘制点
  Offset? get startPoint => _startPoint;

  ui.Offset get endPoint => endPoint;
  Rect? bounds;
  Rect? selectedRect;

  Timer? _timer;
  Function? callBack;
  //String text = "";
  bool isHandlerAdded = false;

  /// Grid on or off
  bool isGridOn = true;
  int gridWidthSpace = 100;
  int gridHeightSpace = 50;
  Paint gridPaint = Paint()
    ..color = ui.Color.fromARGB(255, 149, 255, 49)
    ..isAntiAlias = true
    ..strokeWidth = 1;

  void gridUpdate(int width, int height) {
    gridWidthSpace = width;
    gridHeightSpace = height;

    refresh();
  }

  void updateSelectedContentColor(Color newColor) {
    if (_selectedContent != null) {
      drawConfig.value = drawConfig.value.copyWith(color: newColor);
      _selectedContent!.paint.color = newColor;
      refresh();
    }
  }

  void changeGrid() {
    isGridOn = !isGridOn;
    refresh();
  }

  drawGrid(Canvas canvas) {
    if (isGridOn && drawConfig.value.size != null) {
      var wid = drawConfig.value.size!.width;
      var hei = drawConfig.value.size!.height;
      for (int i = 0; i < wid; i += gridWidthSpace) {
        canvas.drawLine(
            Offset(i.toDouble(), 0), Offset(i.toDouble(), hei), gridPaint);
      }

      for (int i = 0; i < hei; i += gridHeightSpace) {
        canvas.drawLine(
            Offset(0, i.toDouble()), Offset(wid, i.toDouble()), gridPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset startPoint, Offset endPoint) {
    const int dashLength = 10;
    const double dashRatio = 0.5;

    final double totalDistance = sqrt(pow(endPoint.dx - startPoint.dx, 2) +
        pow(endPoint.dy - startPoint.dy, 2));

    const double actualDashLength = dashLength * dashRatio;
    const double gapLength = dashLength - actualDashLength;

    final dx = (endPoint.dx - startPoint.dx) / totalDistance;
    final dy = (endPoint.dy - startPoint.dy) / totalDistance;

    double currentX = startPoint.dx;
    double currentY = startPoint.dy;
    double remainingDistance = totalDistance;

    while (remainingDistance > 0) {
      final double endX =
          currentX + dx * min(actualDashLength, remainingDistance);
      final double endY =
          currentY + dy * min(actualDashLength, remainingDistance);

      canvas.drawLine(
          Offset(currentX, currentY), Offset(endX, endY), gridPaint);

      remainingDistance -= actualDashLength + gapLength;
      currentX = endX + dx * gapLength;
      currentY = endY + dy * gapLength;
    }
  }

  /// 设置画板大小
  void setBoardSize(Size? size) {
    drawConfig.value = drawConfig.value.copyWith(size: size);
  }

  /// 手指落下
  void addFingerCount(Offset offset) {
    drawConfig.value = drawConfig.value
        .copyWith(fingerCount: drawConfig.value.fingerCount + 1);
  }

  /// 手指抬起
  void reduceFingerCount(Offset offset) {
    if (drawConfig.value.fingerCount <= 0) {
      return;
    }

    drawConfig.value = drawConfig.value
        .copyWith(fingerCount: drawConfig.value.fingerCount - 1);
  }

  /// 设置绘制样式
  void setStyle({
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeMiterLimit,
    double? strokeWidth,
    PaintingStyle? style,
  }) {
    drawConfig.value = drawConfig.value.copyWith(
      blendMode: blendMode,
      color: color,
      colorFilter: colorFilter,
      filterQuality: filterQuality,
      imageFilter: imageFilter,
      invertColors: invertColors,
      isAntiAlias: isAntiAlias,
      maskFilter: maskFilter,
      shader: shader,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      strokeWidth: strokeWidth,
      style: style,
    );
  }

  late PaintContent lastSelected;

  /// 设置绘制内容
  void setPaintContent(PaintContent content) {
    if (content.runtimeType != EmptyContent) {
      lastSelected = content;
    }
    content.paint = drawConfig.value.paint;
    _paintContent = content;
    drawConfig.value =
        drawConfig.value.copyWith(contentType: content.runtimeType);
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final LogicalKeyboardKey logicalKey = event.logicalKey;
      if (logicalKey == LogicalKeyboardKey.enter) {
        (currentContent! as TextPaint)
            .updateText('${(currentContent! as TextPaint).text}\n');
        return true;
      } else if (logicalKey == LogicalKeyboardKey.backspace) {
        (currentContent! as TextPaint).updateText((currentContent! as TextPaint)
            .text
            .substring(0, (currentContent! as TextPaint).text.length - 1));
        return true;
      } else if (logicalKey.keyLabel.isNotEmpty && event.character != null) {
        (currentContent! as TextPaint).updateText(
            '${(currentContent! as TextPaint).text}${event.character!}');
        return true;
      }
    }
    return false;
  }

  /// 添加一条绘制数据
  void addContent(PaintContent content) {
    _history.add(content);
    _currentIndex++;
    _refreshDeep();
  }

  void runTimer() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 100), (Timer timer) {
      for (final PaintContent scene in _history) {
        if (scene.timestamp == PaintContent.selectedTimestamp) {
          callBack = scene.updateUI;
          callBack!.call();
          refresh();
        }
      }
      refresh();
      _refreshDeep();
    });
  }

  void cancelTimer() {
    _timer?.cancel();
  }

  /// 添加多条数据
  void addContents(List<PaintContent> contents) {
    _history.addAll(contents);
    _currentIndex += contents.length;
    _refreshDeep();
  }

  /// * 旋转画布
  /// * 设置角度
  void turn() {
    drawConfig.value =
        drawConfig.value.copyWith(angle: (drawConfig.value.angle + 1) % 4);
  }

  /// 开始绘制
  void startDraw(Offset startPoint) {
    _startPoint = startPoint;
    currentContent = _paintContent.copy();
    currentContent?.paint = drawConfig.value.paint;
    currentContent?.startDraw(startPoint);
    bounds = Rect.fromLTRB(
        startPoint.dx, startPoint.dy, startPoint.dx, startPoint.dy);
// Store the current content as the last drawn content
    PaintContent.selectedTimestamp = currentContent!.timestamp;
    callBack = currentContent!.updateUI;

    if (isHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_handleKey);
      isHandlerAdded = false;
    }

    if (currentContent.runtimeType == TextPaint) {
      isHandlerAdded = true;
      HardwareKeyboard.instance.addHandler(_handleKey);
    }
  }

  /// 取消绘制
  void cancelDraw() {
    _startPoint = null;
    currentContent = null;
  }

  /// 正在绘制
  void drawing(Offset nowPaint) {
    currentContent?.drawing(nowPaint);
    var rect = Rect.fromCenter(center: nowPaint, width: 0, height: 0);
    if (bounds!.contains(rect.inflate(10.0).topLeft) &&
        bounds!.contains(rect.inflate(10.0).bottomRight)) {
      bounds = bounds!.inflate(-10.0);
    } else {
      bounds = bounds!.expandToInclude(rect.inflate(10.0));
    }
    refresh();
  }

  /// 结束绘制
  void endDraw() {
    _startPoint = null;
    final int hisLen = _history.length;

    if (hisLen > _currentIndex) {
      _history.removeRange(_currentIndex, hisLen);
    }

    if (currentContent != null) {
      if (_history.indexWhere(
              (element) => element.timestamp == currentContent!.timestamp) ==
          -1) {
        _history.add(currentContent!);
        _currentIndex = _history.length;
      }

      if (currentContent!.runtimeType != TextPaint) {
        currentContent = null;
      }
    }

    // Update bounds to fit the current content
    bounds = Rect.fromPoints(
      Offset(bounds!.left + 10, bounds!.top + 10),
      Offset(bounds!.right - 10, bounds!.bottom - 10),
    );

    refresh();
    _refreshDeep();
    notifyListeners();
  }

  /// 撤销
  void undo() {
    if (_currentIndex > 0) {
      _currentIndex = _currentIndex - 1;
      _refreshDeep();
    }
  }

  void selectContent(PaintContent content) {
    if (_selectedContent != null) {
      _selectedContent!.isSelected = false;
    }
    _selectedContent = content;
    currentContent = content;
    PaintContent.selectedTimestamp = content.timestamp;
    callBack = content.updateUI;
    if (isHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_handleKey);
      isHandlerAdded = false;
    }

    if (content.runtimeType == TextPaint) {
      isHandlerAdded = true;
      HardwareKeyboard.instance.addHandler(_handleKey);
    }

    _selectedContent!.isSelected = true;
    notifyListeners();
  }

  void deselectContent() {
    if (_selectedContent != null) {
      if (_selectedContent.runtimeType == Circle) {
        (_selectedContent! as Circle).direction = 5;
      }
      _selectedContent!.isSelected = false;
      _selectedContent = null;
      currentContent = null;
      PaintContent.selectedTimestamp = null;
      callBack = null;
      if (isHandlerAdded) {
        HardwareKeyboard.instance.removeHandler(_handleKey);
        isHandlerAdded = false;
      }
      notifyListeners();
    }
  }

  void handlerOff() {
    if (isHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_handleKey);
      isHandlerAdded = false;
    }
  }

  /// Check if undo is available.
  /// Returns true if possible.
  bool canUndo() {
    if (_currentIndex > 0) {
      return true;
    } else {
      return false;
    }
  }

  /// 重做
  void redo() {
    if (_currentIndex < _history.length) {
      _currentIndex = _currentIndex + 1;
      _refreshDeep();
    }
  }

  /// Check if redo is available.
  /// Returns true if possible.
  bool canRedo() {
    if (_currentIndex < _history.length) {
      return true;
    } else {
      return false;
    }
  }

  PaintContent? getContentAtPosition(Offset position) {
    for (final PaintContent content in _history) {
      if (content.containsContent(position)) {
        setPaintContent(EmptyContent());
        return content;
      }
    }
    return null;
  }

  void removePaintContentByTimestamp(DateTime timestamp) {
    final int index = _history
        .indexWhere((PaintContent content) => content.timestamp == timestamp);
    if (index != -1) {
      _history.removeAt(index);
      _currentIndex = max(_currentIndex - 1, 0);
      _refreshDeep();
    }
  }

  /// 清理画布
  void clear() {
    _history.clear();
    _currentIndex = 0;
    _refreshDeep();
  }

  /// 获取图片数据
  Future<ByteData?> getImageData() async {
    try {
      final RenderRepaintBoundary boundary = painterKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(
          pixelRatio: View.of(painterKey.currentContext!).devicePixelRatio);
      return await image.toByteData(format: ui.ImageByteFormat.png);
    } catch (e) {
      debugPrint('获取图片数据出错:$e');
      return null;
    }
  }

  /// 获取画板内容Json
  List<Map<String, dynamic>> getJsonList() {
    return _history.map((PaintContent e) => e.toJson()).toList();
  }

  /// 刷新表层画板
  void refresh() {
    painter?._refresh();
  }

  /// 刷新底层画板
  void _refreshDeep() {
    realPainter?._refresh();
  }

  /// 销毁控制器
  @override
  void dispose() {
    if (!_mounted) {
      return;
    }

    drawConfig.dispose();
    realPainter?.dispose();
    painter?.dispose();

    _mounted = false;

    super.dispose();
  }
}

/// 画布刷新控制器
class RePaintNotifier extends ChangeNotifier {
  void _refresh() {
    notifyListeners();
  }
}
