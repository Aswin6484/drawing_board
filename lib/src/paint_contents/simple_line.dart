import 'package:flutter/painting.dart';
import '../draw_path/draw_path.dart';
import '../paint_extension/ex_paint.dart';

import 'paint_content.dart';

/// 普通自由线条
class SimpleLine extends PaintContent {
  SimpleLine({DateTime? timestamp})
      : super(timestamp: timestamp ?? DateTime.now());

  SimpleLine.data({
    required this.path,
    required Paint paint,
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now()) {
    this.paint = paint;
  }

  factory SimpleLine.fromJson(Map<String, dynamic> data) {
    return SimpleLine.data(
      path: DrawPath.fromJson(data['path'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }

  /// 绘制路径
  DrawPath path = DrawPath();

  @override
  void startDraw(Offset startPoint) =>
      path.moveTo(startPoint.dx, startPoint.dy);

  @override
  void drawing(Offset nowPoint) => path.lineTo(nowPoint.dx, nowPoint.dy);

  @override
  void draw(Canvas canvas, Size size, bool deeper) =>
      canvas.drawPath(path.path, paint);

  @override
  SimpleLine copy() => SimpleLine();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'path': path.toJson(),
      'paint': paint.toJson(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool containsContent(Offset offset) {
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
  void editDrawing(Offset nowPoint) {
    // TODO: implement editDrawing
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
  void updateScale(Offset position) {
    // TODO: implement updateScale
  }
}
