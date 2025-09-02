//TODO: this rebuilds a few to many times in use, I could probably use riverpod to make this nicer as there is only one of everything
//that or change notfiers
//it shouldn't cause a major performance impact because everything here is a relatively simple widget
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:parrotaac/backend/project/authentication/math_problem_generator.dart';
import 'package:parrotaac/extensions/string.dart';
import 'package:parrotaac/extensions/text_editing_controller.dart';

import 'admin_authentication_states.dart';

///onAccept and onReject is the preferred way to access the dialog. but it does return if the user was successfully authenticated
Future<AdminAuthenticationState> showMathAuthenticationPopup(
  BuildContext context,
  MathProblem problem, {
  VoidCallback? onAccept,
  VoidCallback? onReject,
}) {
  const double buttonSize = 75;
  const double textBarMaxWidth = buttonSize * 3 + 16;
  const double textBarMaxHeight = 65;
  const double questionFontSize = 35;

  return showDialog<AdminAuthenticationState>(
    context: context,
    builder: (context) {
      return MathProblemDialog(
        questionFontSize: questionFontSize,
        textBarMaxHeight: textBarMaxHeight,
        textBarMaxWidth: textBarMaxWidth,
        onAccept: onAccept,
        onReject: onReject,
        mathProblem: problem,
      );
    },
  ).then((val) {
    assert(
      val != null,
      "something went wrong with the math authentication, value was null",
    );
    return val ?? AdminAuthenticationState.canceled;
  });
}

class MathProblemDialog extends StatefulWidget {
  const MathProblemDialog({
    super.key,
    required this.questionFontSize,
    required this.textBarMaxHeight,
    required this.textBarMaxWidth,
    required this.mathProblem,
    this.onAccept,
    this.onReject,
  });

  final double questionFontSize;
  final double textBarMaxHeight;
  final double textBarMaxWidth;
  final MathProblem mathProblem;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  State<MathProblemDialog> createState() => _MathProblemDialogState();
}

class _MathProblemDialogState extends State<MathProblemDialog> {
  static const int _maxWrongAttempts = 3;
  final FocusNode _focusNode = FocusNode();
  int wrongAttemptCount = 0;
  late final TextEditingController textController;
  late final ValueNotifier<bool> onWrongAnswerCoolDown;
  late MathProblem problem;
  bool _accepted = false;
  bool _rejected = false;
  @override
  void initState() {
    problem = widget.mathProblem;
    textController = TextEditingController();
    onWrongAnswerCoolDown = ValueNotifier(false);
    super.initState();
  }

  @override
  void dispose() {
    onWrongAnswerCoolDown.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget keypad = ValueListenableBuilder(
        valueListenable: onWrongAnswerCoolDown,
        builder: (context, val, _) {
          return NumericKeypad(
            isEnabled: !val,
            controller: textController,
            buttonColor: Colors.green.withAlpha(220),
          );
        });

    textController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_accepted) {
        Navigator.of(context).pop(AdminAuthenticationState.accepted);
        widget.onAccept?.call();
      }

      if (_rejected) {
        Navigator.of(context).pop(AdminAuthenticationState.rejected);
        widget.onReject?.call();
      }
    });

    final String currentAnswer = textController.text;
    if (problem.answerLength == currentAnswer.length) {
      if (problem.verifyGuess(currentAnswer)) {
        setState(() {
          _accepted = true;
        });
      } else if (wrongAttemptCount >= _maxWrongAttempts - 1) {
        _rejected = true;
      } else {
        onWrongAnswerCoolDown.value = true;
        Future.delayed(Duration(milliseconds: 300)).then((_) {
          if (mounted) {
            onWrongAnswerCoolDown.value = false;
            textController.clear();
          }
        });

        wrongAttemptCount++;
        problem = getMultiplicationProblem();
      }
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (k) {
        if (onWrongAnswerCoolDown.value) {
          return;
        }
        if (k is KeyDownEvent) {
          bool pressedBackspace = k.logicalKey == LogicalKeyboardKey.backspace;
          bool pressedDelete = k.logicalKey == LogicalKeyboardKey.delete;

          if (pressedBackspace || pressedDelete) {
            textController.backspace();
          }

          bool isInt = k.character?.isInt ?? false;
          if (isInt) {
            textController.text += k.character!;
          }
        }
      },
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "multiplication problem",
              style: TextStyle(fontSize: 18),
            ),
            IconButton(
              onPressed: () =>
                  Navigator.of(context).pop(AdminAuthenticationState.canceled),
              icon: Icon(Icons.close),
            )
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                problem.question,
                style: TextStyle(fontSize: widget.questionFontSize),
              ),
              _TextBar(
                  onCooldownController: onWrongAnswerCoolDown,
                  text: textController.text,
                  height: widget.textBarMaxHeight,
                  width: widget.textBarMaxWidth),
              SizedBox(height: 10),
              keypad,
            ],
          ),
        ),
      ),
    );
  }
}

//TODO: use multiple sizes for different width heights and view, or then numbers can be replaced by svg's
class NumericKeypad extends StatelessWidget {
  final TextEditingController controller;
  final double buttonSize;
  final double fontSize;
  final Color textColor;
  final Color buttonColor;
  final bool isEnabled;
  //final ButtonStyle buttonStyle;
  const NumericKeypad({
    super.key,
    required this.controller,
    required this.buttonColor,
    this.isEnabled = true,
    this.buttonSize = 75,
    this.fontSize = 50,
    this.textColor = Colors.white,
  });
  @override
  Widget build(BuildContext context) {
    final List<Widget> lastRow = [];

    lastRow.add(SizedBox(width: buttonSize, height: buttonSize));
    lastRow.add(_numpadButton('0', isEnabled));
    lastRow.add(
      SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: textColor,
          ),
          onPressed: controller.backspace,
          icon: Icon(Icons.backspace_outlined, size: fontSize),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3'], isEnabled),
        _buildRow(['4', '5', '6'], isEnabled),
        _buildRow(['7', '8', '9'], isEnabled),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: lastRow),
      ],
    );
  }

  Widget _buildRow(List<String> digits, bool keyPadEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        if (digit.isEmpty) {
          return SizedBox(width: buttonSize, height: buttonSize); // spacer
        }
        return _numpadButton(digit, keyPadEnabled);
      }).toList(),
    );
  }

  Widget _numpadButton(String text, bool enabled) {
    return Padding(
      padding: const EdgeInsets.all(2.0), // very minimal spacing
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.green.withAlpha(220),
            elevation: 2,
          ),
          onPressed: () {
            if (enabled) {
              controller.text += text;
            }
          },
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _TextBar extends StatelessWidget {
  final String text;
  final double? width;
  final double? height;
  final ValueNotifier<bool> onCooldownController;
  const _TextBar({
    required this.text,
    required this.onCooldownController,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: onCooldownController,
        builder: (context, val, _) {
          return ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: width ?? double.infinity,
                maxHeight: height ?? double.infinity),
            child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: val ? Colors.red : Colors.white,
                ),
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 32),
                  ),
                )),
          );
        });
  }
}

class KeyPadController extends ChangeNotifier {
  String text = "";
  ValueNotifier colorController = ValueNotifier(Colors.white);
}
