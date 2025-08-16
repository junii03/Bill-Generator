import 'package:intl/intl.dart';
import '../services/settings_service.dart';

class FormatUtil {
  static String money(double value, SettingsProvider settings) {
    final f = NumberFormat.currency(
      name: settings.currencySymbol,
      symbol: '${settings.currencySymbol} ',
      decimalDigits: 2,
    );
    return f.format(value);
  }

  static String number(double value, {int decimals = 2}) =>
      value.toStringAsFixed(decimals);
}
