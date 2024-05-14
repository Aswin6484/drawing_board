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
}
