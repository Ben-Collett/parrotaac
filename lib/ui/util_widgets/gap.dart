import 'package:flutter/widgets.dart';

class VerticalGap extends StatelessWidget {
  final double minHeight, maxHeight;
  const VerticalGap({
    super.key,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      child: SizedBox(height: maxHeight),
    );
  }
}
