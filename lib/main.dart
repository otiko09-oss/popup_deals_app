import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'config/firebase/firebase_init.dart';
import 'config/routes/router_config.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/monitoring_service.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    Logger().e('FlutterError: ${details.exception}',
        error: details.exception, stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    Logger()
        .e('PlatformDispatcher error: $error', error: error, stackTrace: stack);
    return true;
  };

  await runZonedGuarded(() async {
    try {
      await FirebaseInitializer.initialize();
      Logger().i('Firebase initialized successfully');
    } catch (e) {
      Logger().e('Firebase initialization error: $e');
    }

    setupServiceLocator();

    final monitoringService = MonitoringService();
    await monitoringService.initialize();
    await monitoringService.logEvent('app_start');

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    Logger().e('Uncaught error: $error', error: error, stackTrace: stack);
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Popup Deals',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ka'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
