import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await FirebaseMessaging.instance.getNotificationSettings();
    } on Object {
      return const NotificationSettings(
        authorizationStatus: AuthorizationStatus.notDetermined,
        alert: AppleNotificationSetting.notSupported,
        announcement: AppleNotificationSetting.notSupported,
        badge: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.never,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
        timeSensitive: AppleNotificationSetting.notSupported,
      );
    }
  }

  Future<NotificationSettings> requestPermission() async {
    try {
      return await FirebaseMessaging.instance.requestPermission();
    } on Object {
      return const NotificationSettings(
        authorizationStatus: AuthorizationStatus.notDetermined,
        alert: AppleNotificationSetting.notSupported,
        announcement: AppleNotificationSetting.notSupported,
        badge: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.never,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
        timeSensitive: AppleNotificationSetting.notSupported,
      );
    }
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } on Object {
      return null;
    }
  }
}
