import 'dart:ui';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 笔触线条
class SmoothLine extends PaintContent {
  SmoothLine(
      {
      /// 绘制影响因子，值越小线条越平滑，粗细变化越慢
      this.brushPrecision = 0.4,
      DateTime? timestamp})
      : super(timestamp: timestamp ?? DateTime.now());

  SmoothLine.data({
    this.brushPrecision = 0.4,
    required this.points,
    required this.strokeWidthList,
    required Paint paint,
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now()) {
    this.paint = paint;
  }

  factory SmoothLine.fromJson(Map<String, dynamic> data) {
    return SmoothLine.data(
      brushPrecision: data['brushPrecision'] as double,
      points: (data['points'] as List<dynamic>)
          .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
          .toList(),
      strokeWidthList: (data['strokeWidthList'] as List<dynamic>)
          .map((dynamic e) => e as double)
          .toList(),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }

  final double brushPrecision;

  /// 绘制点列表
  late List<Offset> points;

  /// 点之间的绘制线条权重列表
  late List<double> strokeWidthList;

  @override
  void startDraw(Offset startPoint) {
    points = <Offset>[startPoint];
    strokeWidthList = <double>[paint.strokeWidth];
  }

  @override
  void drawing(Offset nowPoint) {
    final double distance = (nowPoint - points.last).distance;

    //原始画笔线条线宽
    final double s = paint.strokeWidth;

    double strokeWidth = s * (s * 2 / (s * distance));

    if (strokeWidth > s * 2) {
      strokeWidth = s * 2;
    }

    //上一个线宽
    final double preWidth = strokeWidthList.last;

    if (strokeWidth - preWidth > brushPrecision) {
      strokeWidth = preWidth + brushPrecision;
    } else if (preWidth - strokeWidth > brushPrecision) {
      strokeWidth = preWidth - brushPrecision;
    }

    //记录点位
    points.add(nowPoint);
    strokeWidthList.add(strokeWidth);
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    for (int i = 1; i < points.length; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(points[i - 1].dx, points[i - 1].dy)
          ..lineTo(points[i].dx, points[i].dy),
        paint.copyWith(
            strokeWidth: strokeWidthList[i], blendMode: BlendMode.src),
      );
    }
  }

  @override
  SmoothLine copy() => SmoothLine(brushPrecision: brushPrecision);

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'brushPrecision': brushPrecision,
      'points': points.map((Offset e) => e.toJson()).toList(),
      'strokeWidthList': strokeWidthList,
      'paint': paint.toJson(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool containsContent(Offset offset) {
    // TODO: implement containsContent
    throw UnimplementedError();
  }

  @override
  // TODO: implement bounds
  Rect get bounds => throw UnimplementedError();

  @override
  void updatePosition(Offset newPosition) {
    // TODO: implement updatePosition
  }

  @override
  Offset getAnchorPoint() {
    // TODO: implement getAnchorPoint
    throw UnimplementedError();
  }

  @override
  void updateUI() {
    // TODO: implement updateUI
  }

  @override
  void rotate(double angle) {
    // TODO: implement rotate
  }

  @override
  void editDrawing(Offset nowPoint) {
    // TODO: implement editDrawing
  }

  @override
  void drawSelection(Canvas canvas) {
    // TODO: implement drawSelection
  }

  @override
  bool isTapOnSelectionCircle(Offset tapOffset) {
    // TODO: implement isTapOnSelectionCircle
    throw UnimplementedError();
  }

  @override
  void updatedragposition(Offset newPosition) {
    // TODO: implement updatedragposition
  }

  @override
  bool checkInsideCanvas(Offset basePoint, Offset updatePosition) {
    final List<Offset> points = [];
    for (final point in points) {
      if (point.dx < 0 ||
          point.dx > basePoint.dx ||
          point.dy < 0 ||
          point.dy > basePoint.dy) {
        return false;
      }
    }
    return true;
  }

  @override
  bool checkComponentInCanvas() {
    return true;
  }
}
