import 'dart:async';
import 'package:flutter/material.dart';
import '../paint_contents.dart';
import 'drawing_controller.dart';
import 'helper/ex_value_builder.dart';

/// 绘图板
class Painter extends StatelessWidget {
  const Painter({
    super.key,
    required this.drawingController,
    this.clipBehavior = Clip.antiAlias,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
  });

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
    PaintContent? content = drawingController.selectedContent;
    if (content != null) {
      if (_UpPainter(controller: drawingController)
          .isClickInCloseButton(pde.localPosition)) {
        drawingController.removePaintContentByTimestamp(content.timestamp);
        drawingController.deselectContent();
      } else {
        content = drawingController.getContentAtPosition(pde.localPosition);
        if (content != null) {
          drawingController.selectContent(content);
        } else {
          drawingController.deselectContent();
        }
      }
    } else {
      content = drawingController.getContentAtPosition(pde.localPosition);
      if (content != null) {
        drawingController.selectContent(content);
      } else {
        drawingController.deselectContent();
      }
    }
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
            onTapDown: (TapDownDetails details) {},
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
    if (controller.currentContent != null) {
      controller.currentContent?.draw(canvas, size, false);
    }
    for (final PaintContent content in controller.getHistory) {
      Rect rect;
      if (content.isSelected) {
        if (content is Circle) {
          final Circle circleContent = content;
          final double width =
              (circleContent.endPoint.dx - circleContent.startPoint.dx).abs();
          final double height =
              (circleContent.endPoint.dy - circleContent.startPoint.dy).abs();
          rect = Rect.fromCenter(
                  center: circleContent.center, width: width, height: height)
              .inflate(4.0);
        } else {
          rect = content.bounds.inflate(4.0);
        }

        // Draw a rectangle around the selected paint content
        canvas.drawRect(
            rect,
            Paint()
              ..color = const Color.fromARGB(255, 148, 145, 145)
              ..strokeWidth = 1.0
              ..style = PaintingStyle.stroke);

        // Calculate position for close icon
        const double iconSize = 10.0;
        const double padding = 4.0;
        final Offset closeIconPosition = Offset(
          rect.right + padding,
          rect.top - padding - iconSize,
        );
        _drawCloseIcon(canvas, closeIconPosition, iconSize);
      }
      // Draw the paint content
      content.draw(canvas, size, false);
    }
  }

  void _drawCloseIcon(Canvas canvas, Offset position, double size) {
    final Paint paint = Paint()
      ..color = Colors.black // Change this to your desired color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      position,
      position.translate(size, size),
      paint,
    );
    canvas.drawLine(
      position.translate(size, 0),
      position.translate(0, size),
      paint,
    );
    canvas.drawRect(
      Rect.fromCircle(
          center: position.translate(size / 2, size / 2), radius: size / 2),
      Paint()..color = Colors.transparent, // Invisible rectangle to detect taps
    );
  }

  bool isClickInCloseButton(Offset clickPosition) {
    const double iconSize = 40.0;
    const double padding = 4.0;

    Rect rect;
    if (controller.selectedContent is Circle) {
      final Circle circleContent = controller.selectedContent! as Circle;
      final double width =
          (circleContent.endPoint.dx - circleContent.startPoint.dx).abs();
      final double height =
          (circleContent.endPoint.dy - circleContent.startPoint.dy).abs();
      rect = Rect.fromCenter(
              center: circleContent.center, width: width, height: height)
          .inflate(4.0);
    } else {
      rect = controller.selectedContent!.bounds.inflate(4.0);
    }

    return clickPosition.dx >= rect.right + padding &&
        clickPosition.dx <= rect.right + padding + iconSize &&
        clickPosition.dy >= rect.top - padding - iconSize &&
        clickPosition.dy <= rect.top - padding;
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeepPainter oldDelegate) => false;
}
