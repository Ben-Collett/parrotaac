import 'package:flutter/material.dart';

import 'widgets/sentence_box.dart';

class SentenceBar extends StatefulWidget {
  final SentenceBoxController? sentenceBoxController;
  final VoidCallback? goBack;
  const SentenceBar({
    super.key,
    this.sentenceBoxController,
    this.goBack,
  });

  @override
  State<SentenceBar> createState() => _SentenceBarState();
}

class _SentenceBarState extends State<SentenceBar> {
  late final SentenceBoxController _controller;
  @override
  void initState() {
    _controller = widget.sentenceBoxController ?? SentenceBoxController();
    super.initState();
  }

  Widget _sentenceBoxButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    const color = Colors.grey;
    return Expanded(
      child: SizedBox.expand(
        child: Material(
          color: color,
          child: InkWell(onTap: onTap, child: Icon(icon)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //TODO: I don't like how the backButton works
    final backButton = _sentenceBoxButton(
      icon: Icons.arrow_back,
      onTap: widget.goBack,
    );
    final clearButton = _sentenceBoxButton(
      icon: Icons.clear,
      onTap: _controller.clear,
    );
    final backSpaceButton = _sentenceBoxButton(
      icon: Icons.backspace,
      onTap: _controller.backSpace,
    );

    final speakButton = _sentenceBoxButton(
      icon: Icons.chat_outlined,
      onTap: _controller.speak,
    );

    return Row(
      children: [
        backButton,
        Flexible(
          flex: 10,
          child: SentenceBox(controller: _controller),
        ),
        speakButton,
        backSpaceButton,
        clearButton,
      ],
    );
  }
}
