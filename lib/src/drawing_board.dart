import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../paint_contents.dart';
import 'drawing_controller.dart';

import 'helper/ex_value_builder.dart';
import 'helper/get_size.dart';
import 'paint_contents/arrow.dart';
import 'paint_contents/ruler.dart';
import 'paint_contents/text_paint.dart';
import 'painter.dart';

/// 默认工具栏构建器
typedef DefaultToolsBuilder = List<DefToolItem> Function(
  Type currType,
  DrawingController controller,
);

/// 画板
class DrawingBoard extends StatefulWidget {
  const DrawingBoard({
    super.key,
    required this.background,
    this.controller,
    this.showDefaultActions = false,
    this.showDefaultTools = false,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.clipBehavior = Clip.antiAlias,
    this.defaultToolsBuilder,
    this.boardClipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boardBoundaryMargin,
    this.boardConstrained = false,
    this.maxScale = 20,
    this.minScale = 0.2,
    this.boardPanEnabled = true,
    this.boardScaleEnabled = true,
    this.boardScaleFactor = 200.0,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.transformationController,
    this.alignment = Alignment.topCenter,
  });

  /// 画板背景控件
  final Widget background;

  /// 画板控制器
  final DrawingController? controller;

  /// 显示默认样式的操作栏
  final bool showDefaultActions;

  /// 显示默认样式的工具栏
  final bool showDefaultTools;

  /// 开始拖动
  final Function(PointerDownEvent pde)? onPointerDown;

  /// 正在拖动
  final Function(PointerMoveEvent pme)? onPointerMove;

  /// 结束拖动
  final Function(PointerUpEvent pue)? onPointerUp;

  /// 边缘裁剪方式
  final Clip clipBehavior;

  /// 默认工具栏构建器
  final DefaultToolsBuilder? defaultToolsBuilder;

  /// 缩放板属性
  final Clip boardClipBehavior;
  final PanAxis panAxis;
  final EdgeInsets? boardBoundaryMargin;
  final bool boardConstrained;
  final double maxScale;
  final double minScale;
  final void Function(ScaleEndDetails)? onInteractionEnd;
  final void Function(ScaleStartDetails)? onInteractionStart;
  final void Function(ScaleUpdateDetails)? onInteractionUpdate;
  final bool boardPanEnabled;
  final bool boardScaleEnabled;
  final double boardScaleFactor;
  final TransformationController? transformationController;
  final AlignmentGeometry alignment;

  /// 默认工具项列表
  static List<DefToolItem> defaultTools(
      Type currType, DrawingController controller) {
    return <DefToolItem>[
      DefToolItem(
          isActive: currType == SimpleLine,
          icon: Icons.edit,
          onTap: () => controller.setPaintContent(SimpleLine())),
      DefToolItem(
          isActive: currType == SmoothLine,
          icon: Icons.brush,
          onTap: () => controller.setPaintContent(Arrow())),
      DefToolItem(
          isActive: currType == StraightLine,
          icon: Icons.show_chart,
          onTap: () => controller.setPaintContent(StraightLine())),
      DefToolItem(
          isActive: currType == TextPaint,
          icon: CupertinoIcons.pencil_ellipsis_rectangle,
          onTap: () => controller.setPaintContent(TextPaint())),
      DefToolItem(
          isActive: currType == Circle,
          icon: CupertinoIcons.circle,
          onTap: () => controller.setPaintContent(Circle())),
      DefToolItem(
          isActive: currType == null,
          icon: CupertinoIcons.arrow_down_right_square,
          onTap: () => controller.setPaintContent(Ruler())),
    ];
  }

  static Widget buildDefaultActions(DrawingController controller) {
    return _DrawingBoardState.buildDefaultActions(controller);
  }

  static Widget buildDefaultTools(DrawingController controller,
      {DefaultToolsBuilder? defaultToolsBuilder, Axis axis = Axis.horizontal}) {
    return _DrawingBoardState.buildDefaultTools(controller,
        defaultToolsBuilder: defaultToolsBuilder, axis: axis);
  }

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  late final DrawingController _controller =
      widget.controller ?? DrawingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _controller.runTimer();
  }

  Offset finalPosition = Offset.zero;
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.cancelTimer();
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = InteractiveViewer(
      maxScale: widget.maxScale,
      minScale: widget.minScale,
      boundaryMargin: widget.boardBoundaryMargin ??
          EdgeInsets.all(MediaQuery.of(context).size.width),
      clipBehavior: widget.boardClipBehavior,
      panAxis: widget.panAxis,
      constrained: widget.boardConstrained,
      onInteractionStart: widget.onInteractionStart,
      onInteractionUpdate: widget.onInteractionUpdate,
      onInteractionEnd: widget.onInteractionEnd,
      scaleFactor: widget.boardScaleFactor,
      panEnabled: widget.boardPanEnabled,
      scaleEnabled: widget.boardScaleEnabled,
      transformationController: widget.transformationController,
      child: Align(alignment: widget.alignment, child: _buildBoard),
    );

    if (widget.showDefaultActions || widget.showDefaultTools) {
      content = Column(
        children: <Widget>[
          Expanded(child: content),
          if (widget.showDefaultActions) buildDefaultActions(_controller),
          if (widget.showDefaultTools)
            buildDefaultTools(_controller,
                defaultToolsBuilder: widget.defaultToolsBuilder),
        ],
      );
    }

    return Listener(
      onPointerDown: (PointerDownEvent pde) =>
          _controller.addFingerCount(pde.localPosition),
      onPointerUp: (PointerUpEvent pue) =>
          _controller.reduceFingerCount(pue.localPosition),
      onPointerCancel: (PointerCancelEvent pce) =>
          _controller.reduceFingerCount(pce.localPosition),
      child: content,
    );
  }

  /// 构建画板
  Widget get _buildBoard {
    return RepaintBoundary(
      key: _controller.painterKey,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: _controller.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) =>
            p.angle != n.angle || p.size != n.size,
        builder: (_, DrawConfig dc, Widget? child) {
          Widget c = child!;

          if (dc.size != null) {
            final bool isHorizontal = dc.angle.toDouble() % 2 == 0;
            final double max = dc.size!.longestSide;

            if (!isHorizontal) {
              c = SizedBox(width: max, height: max, child: c);
            }
          }

          return Transform.rotate(angle: dc.angle * pi / 2, child: c);
        },
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[_buildImage, _buildPainter],
          ),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    final PaintContent selectedContent = _controller.selectedContent!;
    if (selectedContent.isTapOnSelectionCircle(details.localPosition)) {
      setState(() {
        selectedContent.startDraw(details.localPosition);
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final PaintContent selectedContent = _controller.selectedContent!;
    setState(() {
      final Offset delta =
          details.localPosition - selectedContent.getAnchorPoint()!;
      finalPosition = details.localPosition;
      selectedContent.updatePosition(finalPosition);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final PaintContent selectedContent = _controller.selectedContent!;
    setState(() {
      // selectedContent.updatePosition(finalPosition);
    });
  }

  /// 构建背景
  Widget get _buildImage => GetSize(
        onChange: (Size? size) => _controller.setBoardSize(size),
        child: widget.background,
      );

  /// 构建绘制层
  Widget get _buildPainter {
    return ExValueBuilder<DrawConfig>(
      valueListenable: _controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) => p.size != n.size,
      builder: (_, DrawConfig dc, Widget? child) {
        return SizedBox(
          width: dc.size?.width,
          height: dc.size?.height,
          child: child,
        );
      },
      child: GestureDetector(
        // onLongPressStart: (LongPressStartDetails details) {
        //   final Offset touchPosition = details.localPosition;
        //   final PaintContent? content =
        //       _controller.getContentAtPosition(details.localPosition);
        //   if (content != null &&
        //       !content.isTapOnSelectionCircle(details.localPosition)) {
        //     setState(() {
        //       _controller.draggingContent = content;
        //       _controller.draggingOffset =
        //           touchPosition - content.getAnchorPoint()!;
        //     });
        //   }
        // },
        // onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
        //   setState(() {
        //     if (_controller.draggingContent != null &&
        //         _controller.draggingOffset != null) {
        //       final Offset newPosition =
        //           details.localPosition - _controller.draggingOffset!;

        //       // Update position of dragging content
        //       _controller.draggingContent!.updatedragposition(newPosition);
        //     }
        //   });
        // },
        // onLongPressEnd: (LongPressEndDetails details) {
        //   setState(() {
        //     _controller.draggingContent = null;
        //     _controller.draggingOffset = null;
        //   });
        // },
        child: Painter(
          drawingController: _controller,
          onPointerDown: widget.onPointerDown,
          onPointerMove: widget.onPointerMove,
          onPointerUp: widget.onPointerUp,
        ),
      ),
    );
  }

  /// 构建默认操作栏
  static Widget buildDefaultActions(DrawingController controller) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          children: <Widget>[
            SizedBox(
              height: 24,
              width: 160,
              child: ExValueBuilder<DrawConfig>(
                valueListenable: controller.drawConfig,
                shouldRebuild: (DrawConfig p, DrawConfig n) =>
                    p.strokeWidth != n.strokeWidth,
                builder: (_, DrawConfig dc, ___) {
                  return Slider(
                    value: dc.strokeWidth,
                    max: 50,
                    min: 1,
                    onChanged: (double v) =>
                        controller.setStyle(strokeWidth: v),
                  );
                },
              ),
            ),
            IconButton(
                icon: const Icon(CupertinoIcons.arrow_turn_up_left),
                onPressed: () => controller.undo()),
            IconButton(
                icon: const Icon(CupertinoIcons.arrow_turn_up_right),
                onPressed: () => controller.redo()),
            IconButton(
                icon: const Icon(CupertinoIcons.rotate_right),
                onPressed: () => controller.turn()),
            IconButton(
                icon: const Icon(CupertinoIcons.trash),
                onPressed: () => controller.clear()),
            SizedBox(
                height: 24,
                width: 160,
                child: Slider(
                  value: controller.gridWidthSpace.toDouble(),
                  max: 500,
                  min: 10,
                  onChanged: (double v) => controller.gridUpdate(
                      v.toInt(), controller.gridHeightSpace),
                )),
            SizedBox(
                height: 24,
                width: 160,
                child: Slider(
                  value: controller.gridHeightSpace.toDouble(),
                  max: 500,
                  min: 10,
                  onChanged: (double v) => controller.gridUpdate(
                      controller.gridWidthSpace, v.toInt()),
                )),
            if (controller.currentContent != null &&
                controller.currentContent!.runtimeType == TextPaint)
              SizedBox(
                  height: 24,
                  width: 160,
                  child: Slider(
                    value: (controller.currentContent! as TextPaint)
                        .fontSize
                        .toDouble(),
                    max: 60,
                    min: 10,
                    onChanged: (double v) =>
                        (controller.currentContent! as TextPaint)
                            .fontUpdate(v.toInt()),
                  )),
            if (controller.currentContent != null &&
                controller.currentContent!.runtimeType == TextPaint)
              SizedBox(
                  height: 24,
                  width: 160,
                  child: Slider(
                    value: (controller.currentContent! as TextPaint)
                        .fontSize
                        .toDouble(),
                    max: 255,
                    min: 10,
                    onChanged: (double v) =>
                        (controller.currentContent! as TextPaint)
                            .fontColorUpdate(
                                Color.fromARGB(255, v.toInt(), 255, 255)),
                  )),
          ],
        ),
      ),
    );
  }

  /// 构建默认工具栏
  static Widget buildDefaultTools(
    DrawingController controller, {
    DefaultToolsBuilder? defaultToolsBuilder,
    Axis axis = Axis.horizontal,
  }) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: axis,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          shouldRebuild: (DrawConfig p, DrawConfig n) =>
              p.contentType != n.contentType,
          builder: (_, DrawConfig dc, ___) {
            final Type currType = dc.contentType;

            final List<Widget> children =
                (defaultToolsBuilder?.call(currType, controller) ??
                        DrawingBoard.defaultTools(currType, controller))
                    .map((DefToolItem item) => _DefToolItemWidget(item: item))
                    .toList();

            return axis == Axis.horizontal
                ? Row(children: children)
                : Column(children: children);
          },
        ),
      ),
    );
  }
}

/// 默认工具项配置文件
class DefToolItem {
  DefToolItem({
    required this.icon,
    required this.isActive,
    this.onTap,
    this.color,
    this.activeColor = Colors.blue,
    this.iconSize,
  });

  final Function()? onTap;
  final bool isActive;

  final IconData icon;
  final double? iconSize;
  final Color? color;
  final Color activeColor;
}

/// 默认工具项 Widget
class _DefToolItemWidget extends StatelessWidget {
  const _DefToolItemWidget({
    required this.item,
  });

  final DefToolItem item;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: item.onTap,
      icon: Icon(
        item.icon,
        color: item.isActive ? item.activeColor : item.color,
        size: item.iconSize,
      ),
    );
  }
}
