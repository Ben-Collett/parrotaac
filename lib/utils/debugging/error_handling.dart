void quickCatch(Function() callback, {Function(dynamic)? onError}) {
  try {
    callback.call();
  } catch (e) {
    onError?.call(e);
  }
}
