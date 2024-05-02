import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'drawing_controller.dart';
import 'helper/ex_value_builder.dart';
import 'paint_contents/paint_content.dart';

/// 绘图板
class Painter extends StatelessWidget {
  const Painter({
    Key? key,
    required this.drawingController,
    this.clipBehavior = Clip.antiAlias,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
  }) : super(key: key);

  /// 绘制控制器
  final DrawingController drawingController;

  /// 开始拖动
  final Function(PointerDownEvent pde)? onPointerDown;

  /// 正在拖动
  final Function(PointerMoveEvent pme)? onPointerMove;

  /// 结束拖动
  final Function(PointerUpEvent pue)? onPointerUp;

  /// 边缘裁剪方式
  final Clip clipBehavior;

  /// 手指落下
  void _onPointerDown(PointerDownEvent pde) {
    if (!drawingController.couldDraw) {
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!drawingController.couldDraw) {
        return;
      }

      drawingController.startDraw(pde.localPosition);
      onPointerDown?.call(pde);
    });
  }

  /// 手指移动
  void _onPointerMove(PointerMoveEvent pme) {
    if (!drawingController.couldDraw) {
      if (drawingController.currentContent != null) {
        drawingController.endDraw();
      }
      return;
    }

    drawingController.drawing(pme.localPosition);
    onPointerMove?.call(pme);
  }

  /// 手指抬起
  void _onPointerUp(PointerUpEvent pue) {
    if (!drawingController.couldDraw ||
        drawingController.currentContent == null) {
      return;
    }

    if (drawingController.startPoint == pue.localPosition) {
      drawingController.drawing(pue.localPosition);
    }

    drawingController.endDraw();
    onPointerUp?.call(pue);
  }

  void _onPointerCancel(PointerCancelEvent pce) {
    if (!drawingController.couldDraw) {
      return;
    }

    drawingController.endDraw();
  }

  /// GestureDetector 占位
  void _onPanDown(DragDownDetails ddd) {}

  void _onPanUpdate(DragUpdateDetails dud) {}

  void _onPanEnd(DragEndDetails ded) {}

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: drawingController.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) =>
            p.fingerCount != n.fingerCount,
        builder: (_, DrawConfig config, Widget? child) {
          return GestureDetector(
            onPanDown: config.fingerCount <= 1 ? _onPanDown : null,
            onPanUpdate: config.fingerCount <= 1 ? _onPanUpdate : null,
            onPanEnd: config.fingerCount <= 1 ? _onPanEnd : null,
            child: child,
          );
        },
        child: ClipRect(
          clipBehavior: clipBehavior,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _DeepPainter(controller: drawingController),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _UpPainter(controller: drawingController),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 表层画板
class _UpPainter extends CustomPainter {
  _UpPainter({required this.controller}) : super(repaint: controller.painter);

  final DrawingController controller;

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.currentContent == null) {
      return;
    }

    controller.currentContent?.draw(canvas, size, false);
  }

  @override
  bool shouldRepaint(covariant _UpPainter oldDelegate) => false;
}

/// 底层画板
class _DeepPainter extends CustomPainter {
  _DeepPainter({required this.controller})
      : super(repaint: controller.realPainter);
  final DrawingController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final List<PaintContent> contents = controller.getHistory;

    if (contents.isEmpty) {
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());

    for (int i = 0; i < controller.currentIndex; i++) {
      contents[i].draw(canvas, size, true);
    }

    // Draw dotted outline rectangle at start and end points modified
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double startXMinus10 = controller.startPoint!.dx - 10;
    final double startYPlus10 = controller.startPoint!.dy + 10;
    final double endXPlus10 = controller.endPoint.dx + 10;
    final double endYMinus10 = controller.endPoint.dy - 10;

    final Path path = Path()
      ..moveTo(startXMinus10, startYPlus10)
      ..lineTo(endXPlus10, startYPlus10)
      ..lineTo(endXPlus10, endYMinus10)
      ..lineTo(startXMinus10, endYMinus10)
      ..close();

    final List<Offset> dashedPoints = _getDashedPoints(path);
    for (int i = 0; i < dashedPoints.length - 1; i += 2) {
      canvas.drawLine(dashedPoints[i], dashedPoints[i + 1], paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeepPainter oldDelegate) => false;

  List<Offset> _getDashedPoints(Path path) {
    final List<Offset> dashedPoints = [];
    final PathMetric metric = path.computeMetrics().first;
    double distance = 0.0;
    while (distance < metric.length) {
      final List<Offset> segment = (metric
              .getTangentForOffset(distance)!
              .position +
          metric.getTangentForOffset(distance + 5)!.position) as List<Offset>;
      dashedPoints.addAll(segment);
      distance += 10; // Increase this value to adjust the dash length
    }
    return dashedPoints;
  }
}
