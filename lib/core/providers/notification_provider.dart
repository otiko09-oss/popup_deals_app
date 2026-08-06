import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:popup_deals_app/core/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationSettingsProvider =
    FutureProvider<NotificationSettings>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getNotificationSettings();
});

final notificationPermissionRequestProvider =
    FutureProvider.family<NotificationSettings, bool>((ref, request) async {
  final service = ref.watch(notificationServiceProvider);
  if (!request) {
    return await service.getNotificationSettings();
  }
  return await service.requestPermission();
});
