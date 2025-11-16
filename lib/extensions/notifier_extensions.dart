import 'package:flutter/material.dart';

extension ChangeNotifierExtensions on ChangeNotifier {
  void executeAndAddListener(VoidCallback listener) {
    listener.call();
    addListener(listener);
  }
}
