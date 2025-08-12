import 'package:flutter/material.dart';
import 'package:parrotaac/restorative_navigator.dart';

class NavigatorBackArrow extends StatelessWidget {
  const NavigatorBackArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => RestorativeNavigator().pop(context),
      icon: Icon(Icons.arrow_back),
    );
  }
}
