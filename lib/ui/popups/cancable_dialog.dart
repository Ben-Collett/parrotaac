import 'package:flutter/material.dart';

class CancableDialog extends StatelessWidget {
  final Widget content;
  final List<Widget>? actionOverride;

  ///if not set then it will invoke Navigator.pop
  final void Function(BuildContext context)? onCancel;
  final void Function(BuildContext context)? onAccept;
  const CancableDialog(
      {super.key,
      required this.content,
      this.actionOverride,
      this.onCancel,
      this.onAccept});

  void _onAccept(BuildContext context) {
    if (onAccept != null) {
      onAccept!(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onCancel(BuildContext context) {
    if (onCancel != null) {
      onCancel!(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    if (actionOverride != null) {
      actions = actionOverride!;
    } else {
      IconButton cancelButton = IconButton(
        color: Colors.red,
        icon: Icon(Icons.cancel_rounded),
        onPressed: () => _onCancel(context),
      );

      IconButton acceptButton = IconButton(
        color: Colors.green,
        icon: Icon(Icons.check),
        onPressed: () => _onAccept(context),
      );
      actions = [cancelButton, acceptButton];
    }
    return AlertDialog(
      content: content,
      actions: actions,
    );
  }
}
