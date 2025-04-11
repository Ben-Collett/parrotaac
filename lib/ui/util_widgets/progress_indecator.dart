import 'package:flutter/widgets.dart';

class ProgressController extends ChangeNotifier {
  int progress;
  int end;
  ProgressMode? mode;

  ProgressController({this.progress = 0, this.end = 0, this.mode});
}

enum ProgressMode { faction, percentage }

class LinearProgress extends StatelessWidget {
  const LinearProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}
