import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:popup_deals_app/core/services/auth_service.dart';
import 'package:popup_deals_app/core/services/firestore_service.dart';
import 'package:popup_deals_app/core/services/storage_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt
    ..registerSingleton<Logger>(Logger())
    ..registerSingleton<AuthService>(AuthService())
    ..registerSingleton<FirestoreService>(FirestoreService())
    ..registerSingleton<StorageService>(StorageService());
}
