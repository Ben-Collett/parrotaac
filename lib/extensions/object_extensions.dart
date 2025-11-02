extension Cast on Object {
  T? safeCast<T>() {
    if (this is T) {
      return this as T;
    }
    return null;
  }
}
