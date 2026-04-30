import 'package:logger/logger.dart';

class Log {
  static final Logger _logger = Logger(printer: PrettyPrinter());

  static void d(dynamic message) {
    _logger.d(message);
  }

  static void i(dynamic message) {
    _logger.i(message);
  }

  static void w(dynamic message) {
    _logger.w(message);
  }

  static void e(dynamic message, {dynamic error, dynamic stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
