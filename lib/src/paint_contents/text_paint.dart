import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../flutter_drawing_board.dart';
import '../../paint_extension.dart';
import 'paint_content.dart';

class TextPaint extends PaintContent {
  TextPaint(this._controller, DateTime? timestamp)
      : super(timestamp: timestamp ?? DateTime.now());

  TextPaint.data(
      {required this.position,
      required this.text,
      required this.fontSize,
      required this.textColor,
      required Paint paint,
      DateTime? timestamp})
      : super(timestamp: timestamp ?? DateTime.now()) {
    this.paint = paint;
  }

  factory TextPaint.fromJson(Map<String, dynamic> data) {
    final List<String> colorComponents = (data['color'] as String).split(',');
    final int alpha = int.parse(colorComponents[0]);
    final int red = int.parse(colorComponents[1]);
    final int green = int.parse(colorComponents[2]);
    final int blue = int.parse(colorComponents[3]);

    return TextPaint.data(
      position: jsonToOffset(data['position'] as Map<String, dynamic>),
      text: data['text'] as String,
      fontSize: data['fontSize'] as int,
      textColor: Color(alpha << 24 | red << 16 | green << 8 | blue),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }
  late DrawingController _controller;
  double _rotation = 0.0;

  double get rotation => _rotation;
  static const int dashWidth = 4;
  static const int dashSpace = 4;
  late Canvas _canvas;
  late Size _size;
  int curserTimer = 0;

  Offset position = Offset.zero;
  String text = '';
  String uiText = '';
  Color textColor = Colors.black;
  int fontSize = 30;
  bool isPipe = true;

  @override
  Offset getAnchorPoint() => position;

  @override
  void updatePosition(Offset newPosition) {
    position = newPosition;
  }

  @override
  void startDraw(Offset startPoint) {
    position = startPoint;
    // HardwareKeyboard.instance.addHandler(_handleKey);
  }

  // bool _handleKey(KeyEvent event) {
  //   if (event is KeyDownEvent) {
  //     final LogicalKeyboardKey logicalKey = event.logicalKey;
  //     if (logicalKey.keyLabel.isNotEmpty && event.character != null) {
  //       text += event.character!;
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  @override
  void drawing(Offset nowPoint) {
    print('Canvas Drawing');
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    //print("Canvas Draw");
    _canvas = canvas;
    _size = size;
    uiText = text;
    if (isPipe && timestamp == PaintContent.selectedTimestamp) {
      uiText += '|';
    }
    _drawDashedLine(_canvas, _size, paint);
  }

  void _drawDashedLine(Canvas canvas, Size size, Paint paint) {
    final TextSpan textSpan = TextSpan(
      text: uiText,
      style: TextStyle(color: textColor, fontSize: fontSize.toDouble()),
    );
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final Offset textPosition = Offset(
      position.dx - textPainter.height / 2,
      position.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textPosition);
  }

  @override
  TextPaint copy() => TextPaint(_controller, timestamp);

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'position': position.toJson(),
      'text': text,
      'fontSize': fontSize,
      'color':
          '${textColor.alpha},${textColor.red},${textColor.green},${textColor.blue}',
      'paint': paint.toJson(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool containsContent(Offset offset) {
    final TextSpan textSpan = TextSpan(
      text: text,
      style: TextStyle(color: textColor, fontSize: fontSize.toDouble()),
    );
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final Rect textBounds = Rect.fromPoints(
      Offset(
        position.dx - textPainter.height / 2,
        position.dy - textPainter.height / 2,
      ),
      Offset(
        position.dx + textPainter.width + textPainter.height / 2,
        position.dy + textPainter.height / 2,
      ),
    );

    return textBounds.contains(offset);
  }

  @override
  Rect get bounds {
    final TextSpan textSpan = TextSpan(
      text: text,
      style: TextStyle(color: textColor, fontSize: fontSize.toDouble()),
    );
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final Rect textBounds = Rect.fromPoints(
      Offset(
        position.dx - textPainter.height / 2,
        position.dy - textPainter.height / 2,
      ),
      Offset(
        position.dx + textPainter.width + textPainter.height / 2,
        position.dy + textPainter.height / 2,
      ),
    );

    return textBounds;
  }

  void updateText(String updatedText) {
    text = updatedText;
  }

  @override
  void updateUI() {
    if (timestamp == PaintContent.selectedTimestamp) {
      updateText(DrawingController.text);
      curserTimer += 1;
      if (curserTimer == 3) {
        curserTimer = 0;
        isPipe = !isPipe;
      }
    }
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
  void updateScale(Offset position) {
    // TODO: implement updateScale
  }
}
