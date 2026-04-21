import 'dart:async';

import 'package:synchronized/synchronized.dart';

class Mutex {
  Lock lock = Lock();

  void synchronized(FutureOr Function() computation) {
    lock.synchronized(computation);
  }
}

class MutexTypeMap {
  final Map<Type, Mutex> _mutexMap = {};

  void synchronized({
    required FutureOr Function() computation,
    required dynamic object,
  }) {
    Type type = object.runtimeType;

    if (!_mutexMap.containsKey(type)) {
      _mutexMap[type] = Mutex();
    }

    _mutexMap[type]!.synchronized(computation);
  }
}
