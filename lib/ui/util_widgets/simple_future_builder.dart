import 'package:flutter/material.dart';
import 'package:parrotaac/backend/caching.dart';

MemoryCache longTermFutureCache = MemoryCache(maxEntries: 300);

class SimpleFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(T data) onData;
  final Widget? loadingWidget;
  final dynamic futureId;

  const SimpleFutureBuilder({
    super.key,
    required this.future,
    required this.onData,

    this.futureId,
    this.loadingWidget,
  });

  @override
  State<SimpleFutureBuilder<T>> createState() => _SimpleFutureBuilderState<T>();
}

class _SimpleFutureBuilderState<T> extends State<SimpleFutureBuilder<T>> {
  T? cachedResult;
  @override
  Widget build(BuildContext context) {
    if (widget.futureId != null &&
        longTermFutureCache.containsKey(widget.futureId)) {
      cachedResult = longTermFutureCache[widget.futureId];
    }
    if (cachedResult != null) {
      return widget.onData(cachedResult as T);
    }
    return FutureBuilder(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          cachedResult = snapshot.data as T;
          if (widget.futureId != null) {
            longTermFutureCache[widget.futureId] = cachedResult;
          }
          return widget.onData(cachedResult as T);
        } else if (snapshot.hasError) {
          return ErrorWidget.withDetails(message: snapshot.error.toString());
        }
        return widget.loadingWidget ?? CircularProgressIndicator();
      },
    );
  }
}
