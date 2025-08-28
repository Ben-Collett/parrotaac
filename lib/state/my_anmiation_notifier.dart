import 'package:flutter/material.dart';

class AnimationNotifier extends AnimationController {
  AnimationNotifier({required super.vsync, super.duration});
  void notify() {
    notifyListeners();
  }
}
