import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';
const _currencyKey = 'app_currency';

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, String>((ref) => CurrencyNotifier());

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('USD') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString(_currencyKey);
    if (currency != null) {
      state = currency;
    }
  }

  Future<void> setCurrency(String currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }
}

/// Supported currencies for global marketplace.
class SupportedCurrencies {
  static const symbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'GEL': '₾',
  };

  static String format(double amount, String currency) {
    final symbol = symbols[currency] ?? currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
