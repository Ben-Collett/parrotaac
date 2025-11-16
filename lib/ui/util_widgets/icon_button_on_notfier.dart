import 'package:flutter/material.dart';

class IconButtonEnabledOnNotfier extends StatelessWidget {
  final ValueNotifier<bool> enabledController;
  final Icon icon;
  final VoidCallback onPressed;
  const IconButtonEnabledOnNotfier({
    super.key,
    required this.enabledController,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: enabledController,
      builder: (context, value, _) {
        return IconButton(onPressed: value ? onPressed : null, icon: icon);
      },
    );
  }
}

class ConditionallyEnabledIconButton extends StatefulWidget {
  final Listenable listenable;
  final Icon icon;
  final bool Function() conditional;
  final Color? color;
  final VoidCallback onPressed;
  const ConditionallyEnabledIconButton({
    super.key,
    required this.icon,
    required this.listenable,
    required this.conditional,
    required this.onPressed,
    this.color,
  });

  @override
  State<ConditionallyEnabledIconButton> createState() =>
      _ConditionallyEnabledIconButtonState();
}

class _ConditionallyEnabledIconButtonState
    extends State<ConditionallyEnabledIconButton> {
  late final ValueNotifier<bool> enabledController;

  @override
  void initState() {
    enabledController = ValueNotifier(widget.conditional());
    widget.listenable.addListener(_updateController);
    super.initState();
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_updateController);
    enabledController.dispose();
    super.dispose();
  }

  void _updateController() => enabledController.value = widget.conditional();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: enabledController,
      builder: (context, value, _) {
        return IconButton(
          onPressed: value ? widget.onPressed : null,
          icon: widget.icon,
          color: widget.color,
        );
      },
    );
  }
}
