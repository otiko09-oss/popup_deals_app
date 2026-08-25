import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenSubscription;

  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _messaging.getNotificationSettings();
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
      return await _messaging.requestPermission();
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
      return await _messaging.getToken();
    } on Object {
      return null;
    }
  }

  /// Requests permission where needed and keeps this device's FCM token on
  /// the user document. The backend can target these tokens for order/deal
  /// updates; token refreshes are handled automatically.
  ///
  /// Bounded with a timeout and never lets an exception escape: this runs
  /// fire-and-forget from the login/register flow (see auth_provider.dart),
  /// so a slow or failing notifications setup must never block — or look
  /// like it's hanging — the actual sign-in.
  Future<void> registerDevice(String userId) async {
    try {
      final settings =
          await requestPermission().timeout(const Duration(seconds: 10));
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await getToken().timeout(const Duration(seconds: 10));
      await _saveToken(userId, token);
      await _tokenSubscription?.cancel();
      _tokenSubscription = _messaging.onTokenRefresh.listen(
        (token) => _saveToken(userId, token),
      );
    } on Object {
      // Notifications are a nice-to-have; never let a failure here be
      // mistaken for (or actually cause) a stuck login.
    }
  }

  Future<void> unregisterDevice(String userId) async {
    final token = await getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    }
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<void> _saveToken(String userId, String? token) async {
    if (token == null || token.isEmpty) return;
    await _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'notificationTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
