import 'package:flutter/foundation.dart';

class EmptyNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
