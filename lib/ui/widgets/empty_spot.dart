import 'package:flutter/material.dart';
import 'package:parrotaac/extensions/color_extensions.dart';

class EmptySpotWidget extends StatelessWidget {
  final Color color;
  const EmptySpotWidget({super.key, this.color = Colors.lightBlue});

  static Color fromBackground(Color color) {
    //TODO: I need to make sure that there is still a contrast for colorblind people using luminosity
    return color.isBluish() ? Colors.red : Colors.lightBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 5)),
        child: Center(
          child: Icon(Icons.add, color: color),
        ),
      ),
    );
  }
}
