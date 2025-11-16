import 'package:parrotaac/backend/simple_logger.dart';

sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  void handle({required Function(T) onSuccess, required Function(E) onError}) {
    if (isOk) {
      onSuccess(unwrap());
    } else {
      onError(unwrapErr());
    }
  }

  T unwrap() => switch (this) {
    Ok(value: final v) => v,
    Err(:final error) => throw Exception("unwrap(): $error"),
  };

  void logIfError({String? messageOverride}) {
    if (isErr) {
      SimpleLogger().logError(messageOverride ?? unwrapErr());
    }
  }

  E unwrapErr() => switch (this) {
    Ok() => throw Exception("unwrapErr() called on Ok"),
    Err(error: final e) => e,
  };
}

class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}
