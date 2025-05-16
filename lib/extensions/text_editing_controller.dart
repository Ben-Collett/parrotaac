import 'package:flutter/material.dart' show TextEditingController;

extension EditingExtensions on TextEditingController {
  void backspace() {
    if (text.isNotEmpty) {
      text = text.substring(0, text.length - 1);
    }
  }
}
