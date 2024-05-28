import 'dart:ui';

import 'paint_content.dart';

class EmptyContent extends PaintContent {
  EmptyContent();

  factory EmptyContent.fromJson(Map<String, dynamic> _) => EmptyContent();

  @override
  PaintContent copy() => EmptyContent();

  @override
  void draw(Canvas canvas, Size size, bool deeper) {}

  @override
  void drawing(Offset nowPoint) {}

  @override
  void startDraw(Offset startPoint) {}

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{};
  }

  @override
  bool containsContent(Offset offset) {
    return false;
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

  @override
  void updateUI() {
    // TODO: implement updateUI
  }

  @override
  void editDrawing(Offset nowPoint) {
    // TODO: implement editDrawing
  }

  @override
  void rotate(double angle) {
    // TODO: implement rotate
  }

  @override
  void drawSelection(Canvas canvas) {
    // TODO: implement drawSelection
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
  bool checkInsideCanvas(Offset basePoint, Offset updatePosition) {
    final List<Offset> points = [];
    for (final point in points) {
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
  bool checkComponentInCanvas() {
    return true;
  }
}
