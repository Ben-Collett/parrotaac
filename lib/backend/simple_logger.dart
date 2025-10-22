import 'package:logger/logger.dart';

class SimpleLogger {
  static final SimpleLogger _instance = SimpleLogger._internal();

  SimpleLogger._internal() {
    _logger = Logger();
  }

  late Logger _logger;

  factory SimpleLogger() => _instance;

  void logInfo(dynamic message) {
    _logger.i(message);
  }

  void logWarning(dynamic message) {
    _logger.w(message);
  }

  void logError(dynamic message) {
    _logger.e(message);
  }

  void logDebug(dynamic message) {
    _logger.d(message);
  }
}
