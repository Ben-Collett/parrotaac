import 'package:flutter/material.dart';
import 'package:parrotaac/ui/popups/color_picker_popup.dart';

class ColorPickerPopupButton extends StatefulWidget {
  final Color? initialColor;
  final ValueNotifier<Color>? notifier;
  final Function(Color)? onChange;
  final Function()? onPressed;
  final Function(Color initialColor, Color newColor)? onClose;

  ///if the [notifier] is null then there needs to be an [initialColor]
  const ColorPickerPopupButton({
    super.key,
    this.notifier,
    this.initialColor,
    this.onPressed,
    this.onChange,
    this.onClose,
  }) : assert(
         notifier != null || initialColor != null,
         "both notifier and initialColor can't be null",
       );

  @override
  State<ColorPickerPopupButton> createState() => _ColorPickerPopupButtonState();
}

class _ColorPickerPopupButtonState extends State<ColorPickerPopupButton> {
  late final ValueNotifier<Color> colorNotifier;
  late Color initialColor;
  @override
  void initState() {
    colorNotifier = widget.notifier ?? ValueNotifier(widget.initialColor!);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.notifier == null) {
      colorNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: colorNotifier,
      builder: (context, value, child) {
        return MaterialButton(
          color: value,
          onPressed: () {
            initialColor = colorNotifier.value;
            widget.onPressed?.call();
            showColorPickerDialog(
              context,
              widget.notifier?.value ?? widget.initialColor!,
              (color) {
                widget.onChange?.call(color);
                colorNotifier.value = color;
              },
            ).then(
              (_) => widget.onClose?.call(initialColor, colorNotifier.value),
            );
          },
        );
      },
    );
  }
}
