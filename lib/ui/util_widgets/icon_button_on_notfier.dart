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
