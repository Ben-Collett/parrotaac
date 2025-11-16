import 'package:flutter/material.dart';

class ConditionallyEnabledTextButton extends StatefulWidget {
  final bool Function() condition;
  final Listenable listenable;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  const ConditionallyEnabledTextButton({
    super.key,
    required this.condition,
    required this.onPressed,
    required this.listenable,
    required this.child,
    this.style,
  });

  @override
  State<ConditionallyEnabledTextButton> createState() =>
      _ConditionallyEnabledTextButtonState();
}

class _ConditionallyEnabledTextButtonState
    extends State<ConditionallyEnabledTextButton> {
  late final ValueNotifier<bool> enabledController;
  @override
  void initState() {
    enabledController = ValueNotifier(widget.condition());
    widget.listenable.addListener(_updateEnabledStatus);
    super.initState();
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_updateEnabledStatus);
    enabledController.dispose();
    super.dispose();
  }

  void _updateEnabledStatus() {
    enabledController.value = widget.condition();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: enabledController,
      builder: (context, isEnabled, child) {
        return TextButton(
          onPressed: isEnabled ? widget.onPressed : null,
          style: widget.style,
          child: widget.child,
        );
      },
    );
  }
}
