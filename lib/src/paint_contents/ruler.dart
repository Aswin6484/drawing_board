import 'dart:math';

import 'package:flutter/material.dart';

import '../../paint_contents.dart';
import '../../paint_extension.dart';

class Ruler extends PaintContent {
  Ruler({DateTime? timestamp}) : super(timestamp: timestamp ?? DateTime.now());

  Ruler.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now()) {
    this.paint = paint;
  }

  factory Ruler.fromJson(Map<String, dynamic> data) {
    return Ruler.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }

  static const int dashWidth = 4;
  static const int dashSpace = 4;
  double _rotation = 0.0;

  double get rotation => _rotation;
  Offset startPoint = Offset.zero;
  Offset endPoint = Offset.zero;

  @override
  Offset getAnchorPoint() => startPoint;

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
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    endPoint = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    // Calculate the midpoint for rotation
    final Offset midpoint = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );

    // Save the current state of the canvas
    canvas.save();

    // Translate the canvas so the midpoint is the origin of rotation
    canvas.translate(midpoint.dx, midpoint.dy);

    // Rotate the canvas around the origin (which is now at the midpoint)
    canvas.rotate(_rotation * pi / 180);

    // Translate back after rotation
    canvas.translate(-midpoint.dx, -midpoint.dy);

    _drawDashedLine(canvas, size, paint);

    // Restore the canvas to its previous state
    canvas.restore();
  }

  void _drawDashedLine(Canvas canvas, Size size, Paint paint) {
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

      canvas.drawLine(Offset(currentX, currentY), Offset(endX, endY), paint);

      remainingDistance -= actualDashLength + gapLength;
      currentX = endX + dx * gapLength;
      currentY = endY + dy * gapLength;
    }

    // Calculate the middle point of the current dash segment
    final double middleX = (startPoint.dx + endPoint.dx) / 2;
    final double middleY = (startPoint.dy + endPoint.dy) / 2;

    final String text = 'Len: ${totalDistance.toStringAsFixed(2)}';

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: paint.color)),
      textDirection: TextDirection.ltr, // Adjust as needed
    )..layout(minWidth: 0, maxWidth: double.infinity);

    // Draw the text with formatted length at the middle point with an offset
    canvas.save(); // Save canvas state

    if (dx < 0) {
      final double textOffsetY = textPainter.height * 2;
      canvas.translate(middleX, middleY);
      canvas.rotate(atan2(dy, dx)); // Rotate by the line's slope
      canvas.translate((textPainter.width * 0.5), textOffsetY);
      canvas.rotate(pi);
    } else {
      final double textOffsetY = textPainter.height;
      canvas.translate(middleX, middleY);
      canvas.rotate(atan2(dy, dx)); // Rotate by the line's slope
      canvas.translate(-(textPainter.width * 0.5), textOffsetY);
    }

    textPainter.paint(
        canvas, Offset.zero); // Draw text at origin (after translation)
    canvas.restore(); // Restore canvas state
  }

  @override
  Ruler copy() => Ruler();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'endPoint': endPoint.toJson(),
      'paint': paint.toJson(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool containsContent(Offset offset) {
    const double toleranceRadius = 20.0;
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
    return distance < toleranceRadius;
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
  void updateUI() {
    // TODO: implement updateUI
  }

  @override
  void drawSelection(Canvas canvas) {
    final Paint paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(startPoint, 6.0, paint);
    canvas.drawCircle(endPoint, 6.0, paint);
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
