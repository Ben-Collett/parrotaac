import 'package:flutter/material.dart';

const _liminanceThreshold = .3; //arbitrary choice.
Color computeContrastingColor(Color color) =>
    color.computeLuminance() >= _liminanceThreshold
        ? Colors.black
        : Colors.white;
