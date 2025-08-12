import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget boldText(String text) {
  return Text(
    text,
    textAlign: TextAlign.left,
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget subsection(String text, Widget child) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      boldText(text),
      child,
    ],
  );
}

Widget space({double maxHeight = 20}) {
  return ConstrainedBox(
    constraints: BoxConstraints(minHeight: 0, maxHeight: maxHeight),
    child: Container(),
  );
}

Widget textInput(
  String label,
  TextEditingController controller,
  double maxWidth, {
  String? hintOverride,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
}) {
  return subsection(
    "$label:",
    ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: maxWidth,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintOverride ?? "enter $label here",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    ),
  );
}

Widget colorPickerButton(
  String label,
  Color color,
  VoidCallback showColorChangeDialog,
) {
  return subsection(
      "$label:",
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: MaterialButton(
            onPressed: showColorChangeDialog,
            color: color,
          ),
        ),
      ));
}
