// lib/utils/app_formatters.dart

import 'package:intl/intl.dart';

class AppFormatters {
  // Formata um valor double para a moeda brasileira (Real)
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR', // Define o local para o Brasil
      symbol: 'R\$',     // Define o símbolo da moeda
      decimalDigits: 2, // Garante 2 casas decimais
    );
    return formatter.format(value);
  }

  // Formata um valor double para quilometragem
  static String formatKm(double value) {
    final formatter = NumberFormat(
      '#,##0.0', // Formato com uma casa decimal e separador de milhar
      'pt_BR',   // Usa o padrão brasileiro para separadores (vírgula para decimal)
    );
    return '${formatter.format(value)} km';
  }
}