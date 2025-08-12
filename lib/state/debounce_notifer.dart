import 'dart:async';
import 'dart:ui';

class Debouncer {
  final Duration delay;
  final VoidCallback action;
  Timer? _timer;

  Debouncer({required this.delay, required this.action});

  void notify() {
    if (_timer?.isActive ?? false) {
      return;
    }

    _timer = Timer(delay, () {
      action();
    });
  }
}
