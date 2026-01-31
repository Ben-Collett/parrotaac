extension NullExtensions<T> on T? {
  T ifNotFoundDefaultTo(T value) => this ?? value;
  void existThen(Function(T) func) {
    if (this != null) {
      func.call(this as T);
    }
  }

  void ifFoundThen(Function(T) func) => existThen(func);

  bool get isNull => this == null;
  bool get isNotNull => this != null;
}
