import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

/// 绘制对象
abstract class PaintContent {
  PaintContent({DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();

  PaintContent.paint(this.paint, this.timestamp);

  final DateTime timestamp;
  Offset position = Offset.zero;
  static DateTime? selectedTimestamp;
  double selectionCircleRadius = 6.0;
  double minDraw = 50.0;
  bool isOnCanvas = false;
  bool isEditing = false;

  /// 画笔
  late Paint paint;

  bool isSelected = false;

  /// 复制实例，避免对象传递
  PaintContent copy();

  /// 绘制核心方法
  /// * [deeper] 当前是否为底层绘制
  /// * 出于性能考虑
  /// * 绘制过程为表层绘制，绘制完成抬起手指时会进行底层绘制
  void draw(Canvas canvas, Size size, bool deeper);

  /// 正在绘制
  void drawing(Offset nowPoint);

  void editDrawing(Offset nowPoint);

  /// 开始绘制
  void startDraw(Offset startPoint);

  bool containsContent(Offset offset);
  bool checkComponentInCanvas();
  Offset? getAnchorPoint();
  void updatePosition(Offset newPosition);
  void updateUI();
  void drawSelection(Canvas canvas);
  Rect get bounds;
  bool isTapOnSelectionCircle(Offset tapOffset);
  void updatedragposition(Offset newPosition);
  void updateScale(Offset position);

  /// toJson
  Map<String, dynamic> toContentJson();

  /// toJson
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': runtimeType.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      ...toContentJson(),
    };
  }
}
