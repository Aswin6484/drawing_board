import 'dart:math';
import 'package:flutter/material.dart';
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
  double _rotation = 0.0;

  double get rotation => _rotation;
  double circleRadius = 6.0;
  Offset? startPoint;
  Offset? endPoint;

  @override
  Offset? getAnchorPoint() => startPoint;

  @override
  void updatePosition(Offset newPosition) {}

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void editDrawing(Offset nowPoint) {
    isEditing = true;
    if ((nowPoint - startPoint!).distance <= selectionCircleRadius) {
      startPoint = endPoint;
      endPoint = nowPoint;
    } else {
      endPoint = nowPoint;
    }
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    canvas.save();
    if (!checkComponentInCanvas() && isEditing) {
      final double dX = endPoint!.dx - startPoint!.dx;
      final double dY = endPoint!.dy - startPoint!.dy;
      final double currentLineLength =
          sqrt(dX * dX + dY * dY); // Calculate current line length

      // Normalize the direction vector for scaling
      final double scaleFactor = minDraw / currentLineLength;
      final double extendedDx = dX * scaleFactor;
      final double extendedDy = dY * scaleFactor;

      endPoint =
          Offset(startPoint!.dx + extendedDx, startPoint!.dy + extendedDy);
    }
    if ((startPoint! - endPoint!).distance < minDraw) {
      Paint drawMinPaint = paint.copyWith(color: paint.color.withOpacity(0.5));
      canvas.drawLine(startPoint!, endPoint!, drawMinPaint);
    } else {
      canvas.drawLine(startPoint!, endPoint!, paint);
    }

    // Restore the canvas to its previous state
    canvas.restore();
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

  @override
  void drawSelection(Canvas canvas) {
    final Paint selectionPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    if (startPoint != null) {
      canvas.drawCircle(startPoint!, circleRadius, selectionPaint);
    }
    if (endPoint != null) {
      canvas.drawCircle(endPoint!, circleRadius, selectionPaint);
    }
  }

  @override
  bool checkComponentInCanvas() {
    return isOnCanvas = !((startPoint! - endPoint!).distance < minDraw);
  }

  @override
  bool isTapOnSelectionCircle(Offset tapOffset) {
    if (startPoint == null || endPoint == null) {
      return false;
    }

    final bool isNearStartPoint =
        (tapOffset - startPoint!).distance <= circleRadius;
    final bool isNearEndPoint =
        (tapOffset - endPoint!).distance <= circleRadius;

    return isNearStartPoint || isNearEndPoint;
  }

  @override
  void updatedragposition(Offset newPosition) {
    final Offset delta = newPosition - startPoint!;
    startPoint = newPosition;
    if (endPoint != null) {
      endPoint = endPoint! + delta;
    }
  }

  @override
  void updateScale(Offset position) {
    // TODO: implement updateScale
  }
}
