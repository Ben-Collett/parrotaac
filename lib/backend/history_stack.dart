import 'dart:collection';

import 'package:openboard_wrapper/obf.dart';

///A stack that will start removing old elements if it passes maxHistorySize
//TODO: I will need to handle if a board is deleted
class BoardHistoryStack {
  final int? maxHistorySize;
  final Queue<Obf> _queue;

  Obf get currentBoard {
    Obf head = _queue.removeLast();
    _queue.add(head);
    return head;
  }

  BoardHistoryStack({
    required this.maxHistorySize,
    required Obf currentBoard,
  }) : _queue = Queue.of([currentBoard]);

  BoardHistoryStack.fromNonEmptyList(
    List<Obf> boards, {
    required this.maxHistorySize,
  }) : _queue = Queue.from(boards);

  Obf pop() {
    return _queue.removeLast();
  }

  List<String> toIdList() {
    String toId(b) => b.id;

    return _queue.map(toId).toList();
  }

  ///allows you to push boards to the history, if the same board is pushed twice in a row the second push is ignored.
  void push(Obf obf) {
    if (obf == currentBoard) {
      return;
    }
    if (_queue.length + 1 == maxHistorySize) {
      _queue.removeFirst();
    }
    _queue.addLast(obf);
  }
}
