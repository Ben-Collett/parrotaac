import 'dart:ui';

import 'package:parrotaac/backend/simple_logger.dart';

Path pathFromPoints(List<Offset> points) {
  if (points.isEmpty) {
    return Path();
  }
  final path = Path();
  path.moveTo(points[0].dx, points[0].dy);
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }
  return path;
}
