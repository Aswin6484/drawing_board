import 'dart:math';

import 'package:flutter/material.dart';
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
  Offset top = Offset.zero;
  Offset bottom = Offset.zero;
  Offset left = Offset.zero;
  Offset right = Offset.zero;
  double circleRadius = 6.0;

  /// 是否为椭圆
  final bool isEllipse;

  /// 从圆心开始绘制
  final bool startFromCenter;

  /// 圆心
  Offset center = Offset.zero;

  int direction = 0;

  /// 半径
  double radius = 0;
  double _rotation = 0.0;

  double get rotation => _rotation;

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
  void updatePosition(Offset newPosition) {}

  @override
  void startDraw(Offset startPoint) {
    this.startPoint = startPoint;
    this.endPoint = startPoint;
    center = startPoint;
  }

  @override
  void drawing(Offset nowPoint) {
    if (!checkComponentInCanvas() && isEditing) {
      return;
    }

    switch (direction) {
      case 0:
        endPoint = nowPoint;
        center = Offset((startPoint.dx + endPoint.dx) / 2,
            (startPoint.dy + endPoint.dy) / 2);
        radius = (endPoint - (startFromCenter ? startPoint : center)).distance;
      case 4:
        if (endPoint.dx - minDraw > nowPoint.dx) {
          startPoint = Offset(nowPoint.dx, startPoint.dy);
        }
        center = Offset((startPoint.dx + endPoint.dx) / 2,
            (startPoint.dy + endPoint.dy) / 2);
        radius = (endPoint - (startFromCenter ? startPoint : center)).distance;
      case 3:
        if (startPoint.dx + minDraw < nowPoint.dx) {
          endPoint = Offset(nowPoint.dx, endPoint.dy);
        }
        center = Offset((startPoint.dx + endPoint.dx) / 2,
            (startPoint.dy + endPoint.dy) / 2);
        radius = (endPoint - (startFromCenter ? startPoint : center)).distance;
      case 2:
        if (startPoint.dy + minDraw < nowPoint.dy) {
          endPoint = Offset(endPoint.dx, nowPoint.dy);
        }
        center = Offset((startPoint.dx + endPoint.dx) / 2,
            (startPoint.dy + endPoint.dy) / 2);
        radius = (endPoint - (startFromCenter ? startPoint : center)).distance;
      case 1:
        if (endPoint.dy - minDraw > nowPoint.dy) {
          startPoint = Offset(startPoint.dx, nowPoint.dy);
        }
        center = Offset((startPoint.dx + endPoint.dx) / 2,
            (startPoint.dy + endPoint.dy) / 2);
        radius = (endPoint - (startFromCenter ? startPoint : center)).distance;
    }
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (!checkComponentInCanvas() && isEditing) {
      final double dX = endPoint.dx - startPoint.dx;
      final double dY = endPoint.dy - startPoint.dy;

      // Normalize the direction vector for scaling
      final double scaleFactorX = minDraw / dX;
      final double scaleFactorY = minDraw / dY;
      final double extendedDx = dX * scaleFactorX;
      final double extendedDy = dY * scaleFactorY;

      if ((endPoint.dx - startPoint.dx) <= minDraw) {
        switch (direction) {
          case 4:
            startPoint = Offset(endPoint.dx + extendedDx + 1, startPoint.dy);
            center = Offset((startPoint.dx + endPoint.dx) / 2,
                (startPoint.dy + endPoint.dy) / 2);
            radius =
                (endPoint - (startFromCenter ? startPoint : center)).distance;
          case 3:
            endPoint = Offset(startPoint.dx + extendedDx + 1, endPoint.dy);
            center = Offset((startPoint.dx + endPoint.dx) / 2,
                (startPoint.dy + endPoint.dy) / 2);
            radius =
                (endPoint - (startFromCenter ? startPoint : center)).distance;
        }
      } else {
        switch (direction) {
          case 2:
            endPoint = Offset(endPoint.dx, startPoint.dy + extendedDy + 1);
            center = Offset((startPoint.dx + endPoint.dx) / 2,
                (startPoint.dy + endPoint.dy) / 2);
            radius =
                (endPoint - (startFromCenter ? startPoint : center)).distance;
          case 1:
            startPoint = Offset(startPoint.dx, endPoint.dy + extendedDy + 1);
            center = Offset((startPoint.dx + endPoint.dx) / 2,
                (startPoint.dy + endPoint.dy) / 2);
            radius =
                (endPoint - (startFromCenter ? startPoint : center)).distance;
        }
      }
    }

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

    Paint temp = paint;
    if (!checkComponentInCanvas()) {
      temp = paint.copyWith(color: paint.color.withOpacity(0.5));
    }

    if (isEllipse) {
      // Draw the rotated ellipse
      canvas.drawOval(Rect.fromPoints(startPoint, endPoint), temp);
    } else {
      // Draw the rotated circle
      canvas.drawCircle(startFromCenter ? startPoint : center, radius, temp);
    }

    canvas.drawLine(Offset.zero, Offset.zero, paint);
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
  bool checkInsideCanvas(Offset basePoint, Offset updatePosition) {
    final Offset delta = updatePosition - center;
    final Offset startPointTemp = startPoint + delta;
    final Offset endPointTemp = endPoint + delta;

    final List<Offset> points = <Offset>[
      startPointTemp,
      endPointTemp,
      updatePosition
    ];
    for (final Offset point in points) {
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
  bool containsContent(Offset offset) {
    if (startPoint.dx > endPoint.dx && startPoint.dy > endPoint.dy) {
      final Offset temp = Offset(startPoint.dx, startPoint.dy);
      startPoint = Offset(endPoint.dx, endPoint.dy);
      endPoint = Offset(temp.dx, temp.dy);
    } else if (startPoint.dx < endPoint.dx && startPoint.dy > endPoint.dy) {
      final Offset startTemp = Offset(startPoint.dx, endPoint.dy);
      final Offset endTemp = Offset(endPoint.dx, startPoint.dy);
      startPoint = Offset(startTemp.dx, startTemp.dy);
      endPoint = Offset(endTemp.dx, endTemp.dy);
    } else if (startPoint.dx > endPoint.dx && startPoint.dy < endPoint.dy) {
      final Offset startTemp = Offset(endPoint.dx, startPoint.dy);
      final Offset endTemp = Offset(startPoint.dx, endPoint.dy);
      startPoint = Offset(startTemp.dx, startTemp.dy);
      endPoint = Offset(endTemp.dx, endTemp.dy);
    }
    if (radius == 0) {
      return false;
    }
    return isPointInShape(offset);
  }

  Offset rotatePoint(Offset point, Offset center, double angle) {
    // Convert angle from degrees to radians
    final double radians = angle * pi / 180;

    // Translate point relative to center
    final translatedPoint = Offset(point.dx - center.dx, point.dy - center.dy);

    // Apply rotation transformation
    final newX =
        translatedPoint.dx * cos(radians) - translatedPoint.dy * sin(radians);
    final newY =
        translatedPoint.dx * sin(radians) + translatedPoint.dy * cos(radians);

    // Translate point back to original coordinate system
    final rotatedPoint = Offset(newX + center.dx, newY + center.dy);

    return rotatedPoint;
  }

  bool isPointInShape(Offset clickPosition) {
    // Rotate the click position by the negative of the rotation angle (optional for circle)
    final rotatedClickPosition = rotatePoint(clickPosition, center, 0);

    if (isEllipse) {
      // Calculate ellipse width and height based on startPoint and endPoint
      final double width = endPoint.dx - startPoint.dx;
      final double height = endPoint.dy - startPoint.dy;
      final double majorRadius =
          (width / 2) + threshold; // Assuming major radius is along width
      final double minorRadius =
          (height / 2) + threshold; // Assuming minor radius is along height

      // Check if the rotated click position is within the ellipse's bounding rectangle
      if (rotatedClickPosition.dx >= center.dx - majorRadius &&
          rotatedClickPosition.dx <= center.dx + majorRadius &&
          rotatedClickPosition.dy >= center.dy - minorRadius &&
          rotatedClickPosition.dy <= center.dy + minorRadius) {
        // Optional: More precise check for ellipse (can be commented out)
        final double dxRatio =
            (rotatedClickPosition.dx - center.dx).abs() / majorRadius;
        final double dyRatio =
            (rotatedClickPosition.dy - center.dy).abs() / minorRadius;
        if (dxRatio <= 1 && dyRatio <= 1) {
          return true;
        }
      }
      return false;
    } else {
      // Check if the rotated click position is within the circle's radius (optional for circle)
      final double distance = sqrt((rotatedClickPosition.dx - center.dx) *
              (rotatedClickPosition.dx - center.dx) +
          (rotatedClickPosition.dy - center.dy) *
              (rotatedClickPosition.dy - center.dy));
      return distance <= radius;
    }
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
  void editDrawing(Offset nowPoint) {
    isEditing = true;
    if ((nowPoint - top).distance <= threshold) {
      direction = 1;
    } else if ((nowPoint - bottom).distance <= threshold) {
      direction = 2;
    } else if ((nowPoint - right).distance <= threshold) {
      direction = 3;
    } else if ((nowPoint - left).distance <= threshold) {
      direction = 4;
    }
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
    return (tapOffset - top).distance <= threshold ||
        (tapOffset - bottom).distance <= threshold ||
        (tapOffset - right).distance <= threshold ||
        (tapOffset - left).distance <= threshold;
  }

  @override
  bool checkComponentInCanvas() {
    bool isOnCanvas = true;
    if ((endPoint.dx - startPoint.dx).abs() <= minDraw ||
        (endPoint.dy - startPoint.dy).abs() <= minDraw) {
      isOnCanvas = false;
    }
    return isOnCanvas;
  }
}
