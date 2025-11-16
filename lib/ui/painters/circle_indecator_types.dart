import 'package:flutter/widgets.dart';

enum SelectedCircleTypes { hidden, empty, selected, selectedRow, selectedCol }

class SelectedCircle extends StatelessWidget {
  final ValueNotifier<SelectedCircleTypes> notifier;
  const SelectedCircle({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        return Container();
      },
    );
  }
}
