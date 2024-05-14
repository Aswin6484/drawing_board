import 'package:flutter/painting.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';

import 'paint_content.dart';

/// 直线
class StraightLine extends PaintContent {
  StraightLine({DateTime? timestamp})
      : super(timestamp: timestamp ?? DateTime.now());

  StraightLine.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now()) {
    this.paint = paint;
  }

  factory StraightLine.fromJson(Map<String, dynamic> data) {
    return StraightLine.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }

  Offset? startPoint;
  Offset? endPoint;
  @override
  Offset? getAnchorPoint() => startPoint;

  @override
  void updatePosition(Offset newPosition) {
    final Offset delta = newPosition - startPoint!;
    startPoint = newPosition;
    if (endPoint != null) {
      endPoint = endPoint! + delta;
    }
  }

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    canvas.drawLine(startPoint!, endPoint!, paint);
  }

  @override
  StraightLine copy() => StraightLine();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool containsContent(Offset offset) {
    const double toleranceRadius = 20.0;
    if (startPoint == null || endPoint == null) {
      return false;
    }

    // Calculate the distance from the start point to the end point
    final double dx = endPoint!.dx - startPoint!.dx;
    final double dy = endPoint!.dy - startPoint!.dy;

    // Calculate the distance from the start point to the given offset
    final double t = ((offset.dx - startPoint!.dx) * dx +
            (offset.dy - startPoint!.dy) * dy) /
        (dx * dx + dy * dy);

    // Check if the given offset is on the line segment
    if (t < 0 || t > toleranceRadius) {
      return false;
    }
    // Calculate the distance from the start point to the projected point
    final double distance = (offset.dx - startPoint!.dx - t * dx) *
            (offset.dx - startPoint!.dx - t * dx) +
        (offset.dy - startPoint!.dy - t * dy) *
            (offset.dy - startPoint!.dy - t * dy);

    // Check if the distance is within a small tolerance (e.g., 1 pixel)
    return distance < toleranceRadius * toleranceRadius;
  }

  @override
  Rect get bounds {
    if (startPoint == null || endPoint == null) {
      return Rect.zero;
    }

    final double left =
        startPoint!.dx < endPoint!.dx ? startPoint!.dx : endPoint!.dx;
    final double top =
        startPoint!.dy < endPoint!.dy ? startPoint!.dy : endPoint!.dy;
    final double right =
        startPoint!.dx > endPoint!.dx ? startPoint!.dx : endPoint!.dx;
    final double bottom =
        startPoint!.dy > endPoint!.dy ? startPoint!.dy : endPoint!.dy;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  void updateUI() {
    // TODO: implement updateUI
  }
}
