import 'package:flutter/material.dart';

abstract class PaintingImageData {
  ///absolute width of image
  double get width;

  ///absolute height of image
  double get height;
  ImageProvider get image;
  void update(Canvas size);
}

class PreportionalImageData {
  //double preportionalWidth;
  //double preportionalHeight;

  ///must be set before getting the absolute width or height
  Size? canvasSize;
}

