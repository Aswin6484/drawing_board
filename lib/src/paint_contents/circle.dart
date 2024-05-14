import 'dart:math';

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

  /// 起始点
  Offset startPoint = Offset.zero;

  /// 结束点
  Offset endPoint = Offset.zero;

  @override
  Offset getAnchorPoint() => center;

  @override
  void updatePosition(Offset newPosition) {
    final Offset delta = newPosition - center;
    startPoint += delta;
    endPoint += delta;
    center = newPosition;
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
    if (isEllipse) {
      canvas.drawOval(Rect.fromPoints(startPoint, endPoint), paint);
    } else {
      canvas.drawCircle(startFromCenter ? startPoint : center, radius, paint);
    }
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
  Rect get bounds => Rect.fromCircle(center: center, radius: radius);

  @override
  void updateUI() {
    // TODO: implement updateUI
  }
}
