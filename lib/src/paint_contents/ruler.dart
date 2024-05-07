import 'dart:math';

import 'package:flutter/material.dart';

import '../../paint_contents.dart';
import '../../paint_extension.dart';

class Ruler extends PaintContent {
  Ruler();

  Ruler.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory Ruler.fromJson(Map<String, dynamic> data) {
    return Ruler.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  static const int dashWidth = 4;
  static const int dashSpace = 4;

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
    _drawDashedLine(canvas, size, paint);
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

      remainingDistance -= (actualDashLength + gapLength);
      currentX = endX + dx * gapLength;
      currentY = endY + dy * gapLength;
    }

    // Calculate the middle point of the current dash segment
    final double middleX = (startPoint.dx + endPoint.dx) / 2;
    final double middleY = (startPoint.dy + endPoint.dy) / 2;

    String text = "Len: ${totalDistance.toStringAsFixed(2)}";

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
    };
  }
}
