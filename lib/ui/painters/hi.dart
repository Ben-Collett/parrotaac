import 'package:flutter/material.dart';

void main(List<String> args) {
  ValueNotifier<bool> showSecondPane = ValueNotifier(false);
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: TextButton(
            onPressed: () => showSecondPane.value = !showSecondPane.value,
            child: Text("change state"),
          ),
        ),
        body: ValueListenableBuilder(
            valueListenable: showSecondPane,
            builder: (context, value, child) {
              return HorizontalAnimatedSplitPane(
                showSecondPane: showSecondPane,
                secondPaneTargetWidth: 50,
              );
            }),
      ),
    ),
  );
}

class HorizontalAnimatedSplitPane extends StatefulWidget {
  final ValueNotifier<bool> showSecondPane;
  final Duration animationDuration;
  final double secondPaneTargetWidth;
  const HorizontalAnimatedSplitPane({
    super.key,
    this.animationDuration = const Duration(milliseconds: 300),
    required this.showSecondPane,
    required this.secondPaneTargetWidth,
  });

  @override
  State<HorizontalAnimatedSplitPane> createState() =>
      _HorizontalAnimatedSplitPaneState();
}

class _HorizontalAnimatedSplitPaneState
    extends State<HorizontalAnimatedSplitPane> with TickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Placeholder();
    });
  }
}
