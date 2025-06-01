import 'dart:collection';

import 'package:openboard_wrapper/obf.dart';

///A stack that will start removing old elements if it passes maxHistorySize
//TODO: I will need to handle if a board is deleted
class BoardHistoryStack {
  final int? maxHistorySize;
  final Queue<Obf> _queue;

  ///used to keep track of the current board
  Obf currentBoard;

  BoardHistoryStack({
    required this.maxHistorySize,
    required this.currentBoard,
  }) : _queue = Queue();

  Obf peek() {
    Obf out = _queue.removeLast();
    _queue.addLast(out);
    return out;
  }

  Obf pop() {
    currentBoard = _queue.removeLast();
    return currentBoard;
  }

  void push(Obf obf) {
    if (_queue.length + 1 == maxHistorySize) {
      _queue.removeFirst();
    }
    _queue.addLast(currentBoard);
    currentBoard = obf;
  }
}
