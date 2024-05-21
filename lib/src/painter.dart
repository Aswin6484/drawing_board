import 'dart:async';
import 'package:flutter/material.dart';
import '../paint_contents.dart';
import 'drawing_controller.dart';
import 'helper/ex_value_builder.dart';

/// 绘图板
class Painter extends StatelessWidget {
  const Painter(
      {super.key,
      required this.drawingController,
      this.clipBehavior = Clip.antiAlias,
      this.onPointerDown,
      this.onPointerMove,
      this.onPointerUp,
      this.onPanUpdate});

  /// 绘制控制器
  final DrawingController drawingController;

  /// 开始拖动
  final Function(PointerDownEvent pde)? onPointerDown;

  /// 正在拖动
  final Function(PointerMoveEvent pme)? onPointerMove;

  /// 结束拖动
  final Function(PointerUpEvent pue)? onPointerUp;

  /// for panUpdate
  final Function(double x, double y)? onPanUpdate;

  /// 边缘裁剪方式
  final Clip clipBehavior;

  /// 手指落下
  void _onPointerDown(PointerDownEvent pde) {
    final PaintContent? content =
        drawingController.getContentAtPosition(pde.localPosition);
    if (content != null) {
      drawingController.selectContent(content);
    } else {
      if (drawingController.selectedContent != null) {
        drawingController.deselectContent();
        drawingController.setPaintContent(drawingController.lastSelected);
        onPointerDown?.call(pde);
        return;
      }
    }

    if (!drawingController.couldDraw) {
      onPointerDown?.call(pde);
      return;
    }
    drawingController.startDraw(pde.localPosition);
    onPointerDown?.call(pde);
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

  void _onPanUpdate(DragUpdateDetails dud) {
    //onPanUpdate?.call(10, 20);
  }

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
            onPanDown: drawingController.couldDraw ? _onPanDown : null,
            onPanUpdate: drawingController.couldDraw ? _onPanUpdate : null,
            onPanEnd: drawingController.couldDraw ? _onPanEnd : null,
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
      // Draw the paint content
      content.draw(canvas, size, false);
      if (content.isSelected) {
        content.drawSelection(canvas);
      }
    }
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
      controller.drawGrid(canvas);
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());

    for (int i = 0; i < controller.currentIndex; i++) {
      contents[i].draw(canvas, size, true);
    }
    controller.drawGrid(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeepPainter oldDelegate) => false;
}
