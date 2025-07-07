// lib/utils/app_formatters.dart

import 'package:intl/intl.dart';

class AppFormatters {
  // Formata um valor double para a moeda brasileira (Real)
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // NOVO: Formata um valor double para custo por KM com 3 casas decimais
  static String formatCurrencyPerKm(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 3, // Usa 3 casas para maior precisão em valores pequenos
    );
    return formatter.format(value);
  }

  // Formata um valor double para quilometragem
  static String formatKm(double value) {
    final formatter = NumberFormat(
      '#,##0.0',
      'pt_BR',
    );
    return '${formatter.format(value)} km';
  }
}