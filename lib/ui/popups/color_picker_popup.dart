import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future<void> showColorPickerDialog(
  BuildContext context,
  Color initialColor,
  Function(Color) onChange, {
  Widget? title,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: onChange,
          ),
        ),
      );
    },
  );
}
