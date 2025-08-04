import 'package:flutter/widgets.dart';

typedef FutureCallback<T> = Future<T> Function();

class FutureController<T> extends ChangeNotifier {
  late Future<T> _future;
  Future<T> get future => _future;
  FutureCallback<T> compute;

  FutureController({required this.compute}) {
    _future = compute();
  }

  void refresh() {
    _future = compute();
    notifyListeners();
  }
}
