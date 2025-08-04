import 'package:flutter/material.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/shared_providers/future_controller.dart';

class FutureControllerBuilder<T> extends StatelessWidget {
  final FutureController<T> controller;
  final Widget Function(T?) onData;
  final Widget Function(Object?)? onError;
  final T? initialData;
  final Widget? onLoad;
  const FutureControllerBuilder({
    super.key,
    required this.controller,
    required this.onData,
    this.onError,
    this.initialData,
    this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => FutureBuilder<T>(
        future: controller.future,
        initialData: initialData,
        builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
          if (snapshot.hasData) {
            return onData(snapshot.data);
          }
          if (snapshot.hasError) {
            SimpleLogger().logError(
              "snapshot in FutureBuilder has error ${snapshot.error}",
            );

            return onError?.call(snapshot.error) ??
                Text("error: ${snapshot.error}");
          }
          return onLoad ?? const CircularProgressIndicator();
        },
      ),
    );
  }
}
