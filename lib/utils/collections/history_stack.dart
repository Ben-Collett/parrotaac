import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:openboard_wrapper/obf.dart';

///A stack that will start removing old elements if it passes maxHistorySize
//TODO: I will need to handle if a board is deleted
class BoardHistoryStack extends ChangeNotifier {
  final int? maxHistorySize;
  final Queue<Obf> _queue;
  VoidCallback? beforeChange;

  int get length => _queue.length;

  Obf get currentBoard => _queue.last;

  Obf? get currentBoardOrNull => _queue.lastOrNull;

  BoardHistoryStack({
    required this.maxHistorySize,
    required Obf? currentBoard,
    this.beforeChange,
  }) : _queue = Queue.of([if (currentBoard != null) currentBoard]);

  BoardHistoryStack.fromNonEmptyList(
    List<Obf> boards, {
    required this.maxHistorySize,
    this.beforeChange,
  }) : _queue = Queue.from(boards);

  Obf pop() {
    beforeChange?.call();
    Obf top = _queue.removeLast();
    notifyListeners();
    return top;
  }

  List<String> toIdList() {
    String toId(b) => b.id;

    return _queue.map(toId).toList();
  }

  ///allows you to push boards to the history, if the same board is pushed twice in a row the second push is ignored.
  void push(Obf obf) {
    if (obf == currentBoardOrNull) {
      return;
    }
    beforeChange?.call();
    if (maxHistorySize != null && _queue.length > maxHistorySize!) {
      _queue.removeFirst();
    }
    _queue.addLast(obf);
    notifyListeners();
  }
}
