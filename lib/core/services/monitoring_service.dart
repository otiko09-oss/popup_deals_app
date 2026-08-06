import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class MonitoringService {
  MonitoringService(
      {FirebaseAnalytics? analytics,
      FirebaseCrashlytics? crashlytics,
      Logger? logger})
      : _analytics = analytics ?? FirebaseAnalytics.instance,
        _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
        _logger = logger ?? Logger();

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  final Logger _logger;

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    await _analytics.setAnalyticsCollectionEnabled(true);
    FlutterError.onError = (details) {
      _logger.e('FlutterError',
          error: details.exception, stackTrace: details.stack);
      _crashlytics.recordFlutterError(details);
    };
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e, stack) {
      _logger.e('Analytics event failed: $name', error: e, stackTrace: stack);
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId ?? 'anonymous');
    } catch (e, stack) {
      _logger.e('Monitoring user id update failed',
          error: e, stackTrace: stack);
    }
  }
}
