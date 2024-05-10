import 'dart:math';
import 'dart:ui';

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
    final dX = endPoint.dx - startPoint.dx;
    final dY = endPoint.dy - startPoint.dy;
    final angle = atan2(dY, dX);

    const arrowAngle = 25 * pi / 180;
    const arrowSize = 15;

    final path = Path();
    path.moveTo(endPoint.dx - arrowSize * cos(angle - arrowAngle),
        endPoint.dy - arrowSize * sin(angle - arrowAngle));
    path.lineTo(endPoint.dx, endPoint.dy);
    path.lineTo(endPoint.dx - arrowSize * cos(angle + arrowAngle),
        endPoint.dy - arrowSize * sin(angle + arrowAngle));
    path.close();

    canvas.drawLine(startPoint, endPoint, paint);
    canvas.drawPath(path, paint);
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
    startPoint = newPosition;
    endPoint = endPoint + delta;
  }
}