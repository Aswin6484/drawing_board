import 'package:flutter/painting.dart';
import '../draw_path/draw_path.dart';
import '../paint_extension/ex_paint.dart';

import 'paint_content.dart';

/// 橡皮
class Eraser extends PaintContent {
  Eraser({this.color = const Color(0xff000000), DateTime? timestamp})
      : super(timestamp: timestamp ?? DateTime.now());

  Eraser.data({
    required this.color,
    required this.drawPath,
    required Paint paint,
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now()) {
    this.paint = paint;
  }

  factory Eraser.fromJson(Map<String, dynamic> data) {
    return Eraser.data(
      color: Color(data['color'] as int),
      drawPath: DrawPath.fromJson(data['path'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 擦除路径
  DrawPath drawPath = DrawPath();
  final Color color;

  @override
  void startDraw(Offset startPoint) {
    drawPath.moveTo(startPoint.dx, startPoint.dy);
  }

  @override
  void drawing(Offset nowPoint) => drawPath.lineTo(nowPoint.dx, nowPoint.dy);

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (deeper) {
      canvas.drawPath(
          drawPath.path, paint.copyWith(blendMode: BlendMode.clear));
    } else {
      canvas.drawPath(drawPath.path, paint.copyWith(color: color));
    }
  }

  @override
  Eraser copy() => Eraser(color: color);

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'color': color.value,
      'path': drawPath.toJson(),
      'paint': paint.toJson(),
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
}
