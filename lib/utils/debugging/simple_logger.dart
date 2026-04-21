import 'package:logger/logger.dart';

mixin CustomLogger {
  void logInfo(dynamic message);
  void logWarning(dynamic message);
  void logError(dynamic message);
  void logDebug(dynamic message);
}

class SimpleLogger implements CustomLogger {
  static final SimpleLogger _instance = SimpleLogger._internal();

  SimpleLogger._internal() {
    _logger = Logger();
  }

  late Logger _logger;

  factory SimpleLogger() => _instance;

  @override
  void logInfo(dynamic message) {
    _logger.i(message);
  }

  @override
  void logWarning(dynamic message) {
    _logger.w(message);
  }

  @override
  void logError(dynamic message) {
    _logger.e(message);
  }

  @override
  void logDebug(dynamic message) {
    _logger.d(message);
  }
}
