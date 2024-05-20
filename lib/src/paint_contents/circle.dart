import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';

import 'paint_content.dart';

/// 圆
class Circle extends PaintContent {
  Circle(
      {this.isEllipse = true, this.startFromCenter = true, DateTime? timestamp})
      : super(timestamp: timestamp ?? DateTime.now());

  Circle.data({
    this.isEllipse = true,
    this.startFromCenter = true,
    required this.center,
    required this.radius,
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
    DateTime? timestamp,
  }) : super(timestamp: timestamp ?? DateTime.now()) {
    this.paint = paint;
  }

  factory Circle.fromJson(Map<String, dynamic> data) {
    return Circle.data(
      isEllipse: data['isEllipse'] as bool,
      startFromCenter: data['startFromCenter'] as bool,
      center: jsonToOffset(data['center'] as Map<String, dynamic>),
      radius: data['radius'] as double,
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }

  /// 是否为椭圆
  final bool isEllipse;

  /// 从圆心开始绘制
  final bool startFromCenter;

  /// 圆心
  Offset center = Offset.zero;

  /// 半径
  double radius = 0;
  double _rotation = 0.0;

  double get rotation => _rotation;
  Offset top = Offset.zero;
  Offset bottom = Offset.zero;
  Offset left = Offset.zero;
  Offset right = Offset.zero;
  double circleRadius = 6.0;

  /// 起始点
  Offset startPoint = Offset.zero;

  /// 结束点
  Offset endPoint = Offset.zero;

  @override
  Offset getAnchorPoint() => center;

  @override
  void updatedragposition(Offset newPosition) {
    final Offset delta = newPosition - center;
    startPoint += delta;
    endPoint += delta;
    center = newPosition;
  }

  @override
  void updateScale(Offset position) {
    // Calculate the new radius based on the distance from the center
    radius = (position - center).distance;
    // Adjust startPoint and endPoint accordingly
    startPoint = center - Offset(radius, radius);
    endPoint = center + Offset(radius, radius);
  }

  @override
  void updatePosition(Offset newPosition) {
    final Offset delta = newPosition - startPoint;
    endPoint = endPoint + delta;

    // Calculate the rotation based on the movement of the endpoint
    final double dX = endPoint.dx - startPoint.dx;
    final double dY = endPoint.dy - startPoint.dy;
    final double angle = atan2(dY, dX);
    // Update rotation of the ellipse
    _rotation = angle;
  }

  @override
  void startDraw(Offset startPoint) {
    this.startPoint = startPoint;
    center = startPoint;
  }

  @override
  void drawing(Offset nowPoint) {
    endPoint = nowPoint;
    center = Offset(
        (startPoint.dx + endPoint.dx) / 2, (startPoint.dy + endPoint.dy) / 2);
    radius = (endPoint - (startFromCenter ? startPoint : center)).distance;
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

    if (isEllipse) {
      // Draw the rotated ellipse
      canvas.drawOval(Rect.fromPoints(startPoint, endPoint), paint);
    } else {
      // Draw the rotated circle
      canvas.drawCircle(startFromCenter ? startPoint : center, radius, paint);
    }

    // Restore the canvas to its previous state
    canvas.restore();
  }

  @override
  Circle copy() => Circle(isEllipse: isEllipse);

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'isEllipse': isEllipse,
      'startFromCenter': startFromCenter,
      'center': center.toJson(),
      'radius': radius,
      'startPoint': startPoint.toJson(),
      'endPoint': endPoint.toJson(),
      'paint': paint.toJson(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool containsContent(Offset offset) {
    const double factor = 1;
    if (radius == 0) {
      return false;
    }

    // Calculate the width and height of the oval
    final double width = (endPoint.dx - startPoint.dx).abs();
    final double height = (endPoint.dy - startPoint.dy).abs();

    // Calculate the semi-major and semi-minor axes
    final double a = max(width, height) / 2;
    final double b = min(width, height) / 2;

    // Calculate the normalized coordinates of the offset
    final double x = (offset.dx - center.dx) / a;
    final double y = (offset.dy - center.dy) / b;

    // Check if the offset is within the oval
    return x * x + y * y <= factor * factor;
  }

  @override
  Rect get bounds {
    final double radius = (endPoint - startPoint).distance / 2;
    return Rect.fromCircle(center: center, radius: radius);
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

    // Radius for the selection circles
    // Calculate the width and height of the oval
    final double width = (endPoint.dx - startPoint.dx).abs() / 2;
    final double height = (endPoint.dy - startPoint.dy).abs() / 2;
    // Calculate positions for the selection circles
    top = Offset(center.dx, center.dy - height);
    bottom = Offset(center.dx, center.dy + height);
    left = Offset(center.dx - width, center.dy);
    right = Offset(center.dx + width, center.dy);

    // Draw selection circles at the calculated positions
    canvas.drawCircle(top, circleRadius, selectionPaint);
    canvas.drawCircle(bottom, circleRadius, selectionPaint);
    canvas.drawCircle(left, circleRadius, selectionPaint);
    canvas.drawCircle(right, circleRadius, selectionPaint);
  }

  @override
  bool isTapOnSelectionCircle(Offset tapOffset) {
    return (tapOffset - top).distance <= circleRadius + 5 ||
        (tapOffset - bottom).distance <= circleRadius + 5 ||
        (tapOffset - right).distance <= circleRadius + 5 ||
        (tapOffset - left).distance <= circleRadius + 5;
  }
}
