import 'package:flutter/services.dart';

/// Centralized haptic feedback — call these on taps, saves, errors, etc.
class HapticService {
  HapticService._();

  /// Light — normal taps, navigation
  static void light() => HapticFeedback.lightImpact();

  /// Medium — toggling favorites, confirming selection
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy — placing order, important action
  static void heavy() => HapticFeedback.heavyImpact();

  /// Success pattern — order confirmed, deal saved
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Error pattern — something went wrong
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Selection — chip selected, tab changed
  static void selection() => HapticFeedback.selectionClick();
}
