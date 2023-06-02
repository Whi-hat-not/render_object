import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() {
  runApp(const ChatAppConversationView());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const ChatAppConversationView());
  }
}

class ChatAppConversationView extends StatefulWidget {
  const ChatAppConversationView({super.key});

  @override
  State<ChatAppConversationView> createState() =>
      _ChatAppConversationViewState();
}

class _ChatAppConversationViewState extends State<ChatAppConversationView> {
  final TextEditingController _controller = TextEditingController();
  final String sentAt = "3 seconds ago";

  @override
  void initState() {
    super.initState();
    _controller.text = "Hello, World!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              (_controller.text != "")
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        color: Colors.blue[100]!,
                        padding: const EdgeInsets.all(15),
                        child: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder:
                              (BuildContext context, value, Widget? child) {
                            return TimestampedChatMessage(
                                text: _controller.text,
                                sentAt: '2 minutes ago',
                                style: const TextStyle(color: Colors.red));
                          },
                        ),
                      ),
                    )
                  : Container(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: TextField(
                  controller: _controller,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class TimestampedChatMessage extends LeafRenderObjectWidget {
  const TimestampedChatMessage(
      {super.key,
      required this.text,
      required this.sentAt,
      required this.style});
  final String text;
  final String sentAt;
  final TextStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return TimestampedChatMessageRenderObject(
      text: text,
      sentAt: sentAt,
      style: style,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, TimestampedChatMessageRenderObject renderObject) {
    renderObject.text = text;
    renderObject.sentAt = sentAt;
    renderObject.style = style;
    renderObject.textDirection = Directionality.of(context);
  }
}

class TimestampedChatMessageRenderObject extends RenderBox {
  TimestampedChatMessageRenderObject({
    required String text,
    required String sentAt,
    required TextStyle style,
    required TextDirection textDirection,
  }) {
    _text = text;
    _sentAt = sentAt;
    _style = style;
    _textDirection = textDirection;
    _textPainter =
        TextPainter(text: textTextSpan, textDirection: _textDirection);
    _sentAtTextPainter =
        TextPainter(text: sentAtTextSpan, textDirection: _textDirection);
  }
  late String _text;
  late String _sentAt;
  late TextStyle _style;
  late TextDirection _textDirection;
  late TextPainter _textPainter;
  late TextPainter _sentAtTextPainter;

  String get text => _text;
  set text(String val) {
    if (val == _text) {
      return;
    }
    val = _text;
    _textPainter.text = textTextSpan;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  String get sentAt => _text;
  set sentAt(String val) {
    if (val == _sentAt) {
      return;
    }
    val = _sentAt;
    _sentAtTextPainter.text = sentAtTextSpan;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextStyle get style => _style;
  set style(TextStyle val) {
    if (val == _style) {
      return;
    }
    _style = val;
    _textPainter.text = textTextSpan;
    _sentAtTextPainter.text = sentAtTextSpan;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection val) {
    if (val == _textDirection) {
      return;
    }
    _textDirection = val;
    _textPainter.textDirection = _textDirection;
    _sentAtTextPainter.textDirection = _textDirection;
  }

  //Saved values from performLayout used in paint
  late bool _sentAtFitsOnLastLine;
  late double _lineHeight;
  late double _lastMessageLineWidth;
  late double _longestLineWidth;
  late double _sentAtLineWidth;
  late int _numMessageLines;

  TextSpan get textTextSpan => TextSpan(text: _text, style: _style);
  TextSpan get sentAtTextSpan => TextSpan(
        text: _sentAt,
        style: _style.copyWith(color: Colors.grey),
      );

  @override
  void performLayout() {
    // final childrenSize = child.layout;  <= not required for leaf nodes
    _textPainter.layout(
        maxWidth: constraints.maxWidth); //textpainter to know its size
    final textLines = _textPainter.computeLineMetrics();

    // Repeat for '_sentAtTextPainter'
    _sentAtTextPainter.layout(maxWidth: constraints.maxWidth);
    _sentAtLineWidth = _sentAtTextPainter.computeLineMetrics().first.width;

    _longestLineWidth = 0;
    for (final line in textLines) {
      _longestLineWidth = max(_longestLineWidth, line.width);
    }
    _lastMessageLineWidth = textLines.last.width;
    _lineHeight = textLines.last.height;
    _numMessageLines = textLines.length;

    final sizeOfMessage = Size(_longestLineWidth, _textPainter.height);

    // Set '_sentAtFitsOnLastLine'
    final lastLineWithDate = _lastMessageLineWidth + (_sentAtLineWidth * 1.1);

    if (textLines.length == 1) {
      _sentAtFitsOnLastLine = lastLineWithDate < constraints.maxWidth;
    } else {
      _sentAtFitsOnLastLine =
          lastLineWithDate < min(_longestLineWidth, constraints.maxWidth);
    }

    late Size computedSize;
    if (!_sentAtFitsOnLastLine) {
      computedSize = Size(
        sizeOfMessage.width,
        sizeOfMessage.height + _sentAtTextPainter.height,
      );
    } else {
      if (textLines.length == 1) {
        computedSize = Size(lastLineWithDate, sizeOfMessage.height);
      } else {
        computedSize = Size(_longestLineWidth, sizeOfMessage.height);
      }
    }
    constraints.constrain(computedSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _textPainter.paint(context.canvas, offset);

    late Offset sentAtOffset;
    if (_sentAtFitsOnLastLine) {
      print('x=> ${offset.dx} + ${size.width} - $_sentAtLineWidth');
      print('y=> ${offset.dy} + $_lineHeight + ${_numMessageLines - 1}');
      sentAtOffset = Offset(offset.dx + (size.width - _sentAtLineWidth),
          offset.dy + (_lineHeight * (_numMessageLines - 1)));
    } else {
      sentAtOffset = Offset(offset.dx + (size.width - _sentAtLineWidth),
          offset.dy + (size.height * _numMessageLines));
    }

    _sentAtTextPainter.paint(context.canvas, sentAtOffset);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.label = '$_text, sent at $_sentAt';
    config.textDirection = _textDirection;
  }
}
