import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }

  static void warning(String message, {String? tag}) {
    _log('WARN', message, tag: tag);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log('ERROR', message, tag: tag);
    if (error != null) {
      _log('ERROR', error.toString(), tag: tag);
    }
    if (kDebugMode && stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void _log(String level, String message, {String? tag}) {
    final prefix = tag != null ? '[$level][$tag]' : '[$level]';
    if (kDebugMode) {
      dev.log('$prefix $message');
    }
  }
}
