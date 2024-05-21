import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../paint_contents.dart';
import '../../paint_extension.dart';

class Arrow extends PaintContent {
  Arrow();

  Arrow.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint, DateTime.now());

  factory Arrow.fromJson(Map<String, dynamic> data) {
    return Arrow.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  static const int dashWidth = 4;
  static const int dashSpace = 4;
  double _rotation = 0.0;

  double get rotation => _rotation;
  Offset startPoint = Offset.zero;
  Offset endPoint = Offset.zero;

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    endPoint = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final double dX = endPoint.dx - startPoint.dx;
    final double dY = endPoint.dy - startPoint.dy;
    final double angle = atan2(dY, dX);

    const double arrowAngle = 25 * pi / 180;
    const double arrowSize = 15;

    // Save the current state of the canvas
    canvas.save();

    // Translate the canvas so the startPoint is the origin of rotation
    canvas.translate(startPoint.dx, startPoint.dy);

    // Rotate the canvas around the origin (which is now at the startPoint)
    canvas.rotate(rotation * pi / 180);

    // Draw the line from startPoint to endPoint
    canvas.drawLine(Offset.zero, Offset(dX, dY), paint);

    // Draw the arrow head
    final Path path = Path();
    path.moveTo(dX - arrowSize * cos(angle - arrowAngle),
        dY - arrowSize * sin(angle - arrowAngle));
    path.lineTo(dX, dY);
    path.lineTo(dX - arrowSize * cos(angle + arrowAngle),
        dY - arrowSize * sin(angle + arrowAngle));
    path.close();
    canvas.drawPath(path, paint);

    // Restore the canvas to its previous state
    canvas.restore();
  }

  @override
  Arrow copy() => Arrow();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'endPoint': endPoint.toJson(),
      'paint': paint.toJson(),
    };
  }

  @override
  Rect get bounds {
    final double left =
        startPoint.dx < endPoint.dx ? startPoint.dx : endPoint.dx;
    final double top =
        startPoint.dy < endPoint.dy ? startPoint.dy : endPoint.dy;
    final double right =
        startPoint.dx > endPoint.dx ? startPoint.dx : endPoint.dx;
    final double bottom =
        startPoint.dy > endPoint.dy ? startPoint.dy : endPoint.dy;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool containsContent(Offset offset) {
    const double toleranceRadius = 20.0;

    // Calculate the distance from the start point to the end point
    final double dx = endPoint.dx - startPoint.dx;
    final double dy = endPoint.dy - startPoint.dy;

    // Calculate the distance from the start point to the given offset
    final double t =
        ((offset.dx - startPoint.dx) * dx + (offset.dy - startPoint.dy) * dy) /
            (dx * dx + dy * dy);

    // Check if the given offset is on the line segment
    if (t < 0 || t > toleranceRadius) {
      return false;
    }
    // Calculate the distance from the start point to the projected point
    final double distance = (offset.dx - startPoint.dx - t * dx) *
            (offset.dx - startPoint.dx - t * dx) +
        (offset.dy - startPoint.dy - t * dy) *
            (offset.dy - startPoint.dy - t * dy);

    // Check if the distance is within a small tolerance (e.g., 1 pixel)
    return distance < toleranceRadius * toleranceRadius;
  }

  @override
  Offset? getAnchorPoint() => startPoint;

  @override
  void updatePosition(Offset newPosition) {
    final Offset delta = newPosition - startPoint;
    endPoint = endPoint + delta;

    // Calculate the rotation based on the movement of the endpoint
    final double dX = endPoint.dx - startPoint.dx;
    final double dY = endPoint.dy - startPoint.dy;
    final double angle = atan2(dY, dX);

    // Update rotation of the arrow
    _rotation = angle;
  }

  @override
  void updateUI() {
    // TODO: implement updateUI
  }

  @override
  void drawSelection(Canvas canvas) {
    final Paint selectionPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(startPoint, selectionCircleRadius, selectionPaint);
    canvas.drawCircle(endPoint, selectionCircleRadius, selectionPaint);
  }

  @override
  bool isTapOnSelectionCircle(Offset tapOffset) {
    return (tapOffset - startPoint).distance <= selectionCircleRadius ||
        (tapOffset - endPoint).distance <= selectionCircleRadius;
  }

  @override
  void updatedragposition(Offset newPosition) {
    // TODO: implement updatedragposition
  }

  @override
  void updateScale(Offset position) {
    // TODO: implement updateScale
  }

  @override
  void editDrawing(Offset nowPoint) {
    if ((nowPoint - startPoint).distance <= selectionCircleRadius) {
      startPoint = endPoint;
      endPoint = nowPoint;
    } else {
      endPoint = nowPoint;
    }
  }
}
