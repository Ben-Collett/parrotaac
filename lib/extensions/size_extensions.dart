import 'dart:ui';

extension Shrink on Size {
  Size shrinkBy(double size) {
    return Size(width - size, height - size);
  }
}

