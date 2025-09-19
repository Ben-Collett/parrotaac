import 'package:flutter/material.dart';

class WidgetFutureBuilder extends StatelessWidget {
  final Future<Widget> widget;

  const WidgetFutureBuilder({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
