import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kCurrency = 'currency_symbol';
  static const _kTax = 'default_tax_percent';
  static const _kDark = 'use_dark_mode';

  String _currencySymbol = 'PKR';
  double _defaultTaxPercent = 0; // e.g. 17 for 17%
  bool _darkMode = false;
  bool _loaded = false;

  String get currencySymbol => _currencySymbol;
  double get defaultTaxPercent => _defaultTaxPercent;
  bool get darkMode => _darkMode;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString(_kCurrency) ?? _currencySymbol;
    _defaultTaxPercent = prefs.getDouble(_kTax) ?? _defaultTaxPercent;
    _darkMode = prefs.getBool(_kDark) ?? _darkMode;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String v) async {
    _currencySymbol = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, v);
    notifyListeners();
  }

  Future<void> setDefaultTaxPercent(double v) async {
    _defaultTaxPercent = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTax, v);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool v) async {
    _darkMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, v);
    notifyListeners();
  }
}
